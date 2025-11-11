create or replace package XTMPAG_UTIL is

  -- Author  : TIAGOPC
  -- Created : 27/03/2023 15:51:03

  procedure pAtivaLogCallStack;

  procedure pDesativaLogCallStack;

  procedure pInicializaLogCallStack;

  procedure pGravaLogCallStack (pCdVinculo in ecadvinculo.cdvinculo%type default null);

  procedure pAtivaLogHRV;

  procedure pDesativaLogHRV;

  procedure pAtivaTriggerLogHRV;

  procedure pDesativaTriggerLogHRV;

  procedure pDebugCalculo (pCdFolhaPagamento in epagfolhapagamento.cdfolhapagamento%type
                         , pCdVinculo in ecadvinculo.cdvinculo%type
                         , pNuMatricula in ecadvinculo.numatricula%type
                         , pNuSeqMatricula in ecadvinculo.nuseqmatricula%type
                         , pDtCalculo in out epagfolhapagamento.dtcalculo%type
                         , pFlCalculoDefinitivo in epagfolhapagamento.flcalculodefinitivo%type default 'N'
                         , pGravarLogHRV in boolean default false
                         , pExcluirLogHRV in boolean default false
                         , pGravarLogCallStack in pls_integer default 0
                         , pApenasExcluirHRV boolean default false
                         , pMsgRetorno out varchar2);

  procedure pExecAntesDoProcCalculo;

  procedure pExcluiFolhaPagamento (pNuAnoMesReferencia epagfolhapagamento.nuanomesreferencia%type
                                 /*, pStrCdFolhaPagamento in varchar2 default null*/);

  procedure pProcessaIndividualParalelo (pExcluirCCAntes in boolean default false
                                       , pReprocessamentoIndividGeral in boolean default false);

  procedure pCriaJobsProcIndividParalelo (pQtJobsParalelos in pls_integer
                                        , pExcluirCCAntes in boolean default false
                                      , pReprocessamentoIndividGeral in boolean default false);

  procedure pInsereLogTST /*(p_local_debug in varchar2, p_param01 in varchar2, p_param02 in varchar2 default null
                         , p_param03 in varchar2 default null, p_param04 in varchar2 default null
                         , p_param05 in varchar2 default null, p_param06 in varchar2 default null)*/;

  procedure pInterrompeProcIndividParalelo;

  function fQtdePessoasCalculadas (pCdHistoricoParamCalculo in epaghistoricoparamcalculo.cdhistoricoparamcalculo%type)
    return pls_integer;

  procedure pVerLogCallStack (pExecutor in varchar2, pCdFolhaPagamento in number, pCdVinculo in number, pExecucaoId in pls_integer default 1);

  /*** EMPENHO ******************************************************************************************/

  procedure pEmpProcNomeTmp (
    pCdCreditoBancario in epaghistoricoempenhorubrica.cdcreditobancario%type,
    pNuRubrica in epagrubrica.nurubrica%type,
    pNuUnidadeOrcamentaria in epaghistoricoempenhorubrica.nuunidadeorcamentaria%type default 41012,
    pCdAgrupamento ecadagrupamento.cdagrupamento%type default 1,
    Resultado out Types.ref_cursor);

  function pEmpRubricaSemElementoDespesa (
    pCdOrgao ecadorgao.cdorgao%type,
    pNuMesReferencia epagfolhapagamento.numesreferencia%type,
    pNuAnoReferencia epagfolhapagamento.nuanoreferencia%type,
    pCdTipoFolhaPagamento epagfolhapagamento.cdtipofolhapagamento%type,
    pCdTipoCalculo epagfolhapagamento.cdtipocalculo%type,
    pNuSequencialFolha epagfolhapagamento.nusequencialfolha%type,
    Resultado out Types.ref_cursor) return pls_integer;

  function pEmpVerLiquidNegativoFolNormal (
    pNuAnoMesReferencia epagfolhapagamento.nuanomesreferencia%type,
    pCdOrgao ecadorgao.cdorgao%type,
    pCdTipoFolhaPagamento epagfolhapagamento.cdtipofolhapagamento%type,
    pCdAgrupamento ecadagrupamento.cdagrupamento%type default 1,
    Resultado out Types.ref_cursor) return pls_integer;

  function pEmpVerLiquidNegativoCapaCC (
    pCdFolhaPagamento epagfolhapagamento.cdfolhapagamento%type,
    Resultado out Types.ref_cursor) return pls_integer;

  function pEmpVerLiquidNegativoPenAlimen (
    pNuAnoMesReferencia epagfolhapagamento.nuanomesreferencia%type,
    pCdOrgao ecadorgao.cdorgao%type,
    pCdTipoFolhaPagamento epagfolhapagamento.cdtipofolhapagamento%type,
    pCdAgrupamento ecadagrupamento.cdagrupamento%type default 1,
    Resultado out Types.ref_cursor) return pls_integer;

  function pEmpServsPensaoNaoEstaoRelCred (
    pCdCreditoBancario in epaghistoricoempenhorubrica.cdcreditobancario%type,
    pNuAnoMesReferencia epagfolhapagamento.nuanomesreferencia%type,
    pCdOrgao ecadorgao.cdorgao%type,
    pCdTipoFolhaPagamento epagfolhapagamento.cdtipofolhapagamento%type,
    pCdTipoCalculo epagfolhapagamento.cdtipocalculo%type,
    Resultado out Types.ref_cursor) return pls_integer;

  function pEmpExisteRubLiquidoNegativo (
    pNuAnoMesReferencia epagfolhapagamento.nuanomesreferencia%type,
    pCdTipoFolhaPagamento epagfolhapagamento.cdtipofolhapagamento%type,
    Resultado out Types.ref_cursor) return pls_integer;

  function pEmpVerDadosBancarDuplicados (
    pNuAnoMesReferencia epagfolhapagamento.nuanomesreferencia%type,
    pCdTipoFolhaPagamento epagfolhapagamento.cdtipofolhapagamento%type,
    Resultado out Types.ref_cursor) return pls_integer;

  function pEmpVerVinculosSemDadosBancar (
    pNuAnoMesReferencia epagfolhapagamento.nuanomesreferencia%type,
    pCdTipoFolhaPagamento epagfolhapagamento.cdtipofolhapagamento%type,
    Resultado out Types.ref_cursor) return pls_integer;

  function pEmpVerLiquidoDaCapa (
    pCdOrgao ecadorgao.cdorgao%type,
    pNuAnoMesReferencia epagfolhapagamento.nuanomesreferencia%type,
    pCdTipoFolhaPagamento epagfolhapagamento.cdtipofolhapagamento%type,
    pCdTipoCalculo epagfolhapagamento.cdtipocalculo%type,
    pNuSequencialFolha epagfolhapagamento.nusequencialfolha%type,
    pFlAtivo epagcapahistrubricavinculo.flativo%type,
    Resultado out Types.ref_cursor) return pls_integer;

  function pEmpVerDescontosCapa_x_CC (
    pCdOrgao ecadorgao.cdorgao%type,
    pNuAnoMesReferencia epagfolhapagamento.nuanomesreferencia%type,
    pCdTipoFolhaPagamento epagfolhapagamento.cdtipofolhapagamento%type,
    pCdAgrupamento ecadagrupamento.cdagrupamento%type default 1,
    Resultado out Types.ref_cursor) return pls_integer;

  function pEmpVerProventosCapa_x_CC (
    pCdOrgao ecadorgao.cdorgao%type,
    pNuAnoMesReferencia epagfolhapagamento.nuanomesreferencia%type,
    pCdTipoFolhaPagamento epagfolhapagamento.cdtipofolhapagamento%type,
    pCdAgrupamento ecadagrupamento.cdagrupamento%type default 1,
    Resultado out Types.ref_cursor) return pls_integer;

  procedure pEmpVerTudo (pNuAnoMesReferencia epagfolhapagamento.nuanomesreferencia%type);

  procedure pEmpVerTudoViaJob (pNuAnoMesReferencia epagfolhapagamento.nuanomesreferencia%type);

end XTMPAG_UTIL;
/
create or replace package body XTMPAG_UTIL is

---------------------------------------------------------------------------------------------------------
procedure pAtivaLogCallStack is

  vExecutor varchar2(30);
  vObs varchar2(1000) := null;

  procedure pInsereExcecao is
  begin
    insert into log_callstack (log_id, executor, date_time, obs)
      values (s_log_callstack.nextval, vExecutor, sysdate, vObs);
  end;

begin

  begin
    --pinserelogdebug('tpc', 'pAtivaLogCallStack', 1, XTMPAG_var.vgVinculo.cdvinculo, vExecutor);
    vExecutor := SYS_CONTEXT('USERENV', 'OS_USER');
    if    -- AGPE
          vExecutor in ('NTSIGRH-APP11$', 'NTSIGRH-APP12$' -- APLICACAO PRD
                      , 'NTSIGRH-APP13$', 'NTSIGRH-APP14$', 'NTSIGRH-APP15$')
       or vExecutor in ('NTSIGRH-APPH11$') -- APLICACAO HOM
       or vExecutor in ('NTSIGRH-QLD$') -- APLICACAO QLD
          -- MP
       or vExecutor in ('SIGRH-HML$') -- APLICACAO HOM
    then
      vExecutor := 'APLICACAO';
      --pinserelogdebug('tpc', 'pAtivaLogCallStack', 2, XTMPAG_var.vgVinculo.cdvinculo, vExecutor);
    elsif vExecutor in ('oradb', 'grid') then
      if sys_context('userenv', 'BG_JOB_ID') is not null then
        vExecutor := 'JOB';
        --pinserelogdebug('tpc', 'pAtivaLogCallStack', 3, XTMPAG_var.vgVinculo.cdvinculo, vExecutor);
      else
        vObs := 'OS_USER é '|| vExecutor ||' mas sem JOB';
        pInsereExcecao;
        vExecutor := 'NINGUEM';
        --pinserelogdebug('tpc', 'pAtivaLogCallStack', 4, XTMPAG_var.vgVinculo.cdvinculo, vExecutor);
      end if;
    elsif vExecutor in ('claudiakz', 'fabiovs', 'ibrowse_fmedeiros', 'luisfc', 'marcelob', 'silvioan', 'tiagopc', 'WS-CI001997') then
      null;
      --pinserelogdebug('tpc', 'pAtivaLogCallStack', 5, XTMPAG_var.vgVinculo.cdvinculo, vExecutor);
    elsif vExecutor in ('NTCIASC-DBATOOL$', 'SIGRHServicosAppPool') then
      vExecutor := 'NINGUEM';
      --pinserelogdebug('tpc', 'pAtivaLogCallStack', 6, XTMPAG_var.vgVinculo.cdvinculo, vExecutor);
    else
      vObs := 'Adicionar em XTMPAG_UTIL.pAtivaLogCallStack: OS_USER '|| vExecutor;
      pInsereExcecao;
      vExecutor := 'NINGUEM';
      --pinserelogdebug('tpc', 'pAtivaLogCallStack', 7, XTMPAG_var.vgVinculo.cdvinculo, vExecutor);
    end if;
    select p.valor
      into vExecutor
      from log_param p
     where p.param = 'GRAVAR_LOG_CALLSTACK'
       and p.valor = vExecutor
       and p.ativo = 1;
    if vExecutor = 'JOB' then
      vExecutor := 'JOB '|| sys_context('userenv', 'BG_JOB_ID');
    end if;
    --pinserelogdebug('tpc', 'pAtivaLogCallStack', 8, XTMPAG_var.vgVinculo.cdvinculo, vExecutor);
  exception
  when others then
    vExecutor := 'NINGUEM';
    --pinserelogdebug('tpc', 'pAtivaLogCallStack', 9, XTMPAG_var.vgVinculo.cdvinculo, vExecutor);
  end; --*/
  --vExecutor := 'tiagopc';
  XTMPAG_var.vgLogCallStack.Executor := vExecutor;

end;

---------------------------------------------------------------------------------------------------------
procedure pDesativaLogCallStack is
begin
  XTMPAG_var.vgLogCallStack.Executor := 'NINGUEM';
  XTMPAG_var.vgLogCallStack.ExecucaoId := 0;
end;

---------------------------------------------------------------------------------------------------------
procedure pInicializaLogCallStack is
begin
  --pinserelogdebug('tpc', 'pInicializaLogCallStack', '');
  if XTMPAG_var.vgLogCallStack.Vinculos is null then
    if SYS_CONTEXT('USERENV', 'OS_USER') in ('oradb', 'grid')
       and sys_context('userenv', 'BG_JOB_ID') is not null
    then
      --pinserelogdebug('tpc', 'pInicializaLogCallStack', sys_context('userenv', 'BG_JOB_ID'));
      XTMPAG_var.vgLogCallStack.Vinculos := ',';
      for rec in (
        select distinct p.cdvinculo
          from log_param_extra p
         where p.param = 'GRAVAR_LOG_CALLSTACK'
           and p.executor = 'JOB'
      ) loop
        XTMPAG_var.vgLogCallStack.Vinculos := XTMPAG_var.vgLogCallStack.Vinculos || to_char(rec.cdvinculo) ||',';
      end loop;
      if XTMPAG_var.vgLogCallStack.Vinculos = ',' then
        XTMPAG_var.vgLogCallStack.Vinculos := null;
      end if;
    end if;
  end if;
  --pinserelogdebug('tpc', 'pInicializaLogCallStack', XTMPAG_var.vgLogCallStack.Vinculos);
end;

---------------------------------------------------------------------------------------------------------
procedure pGravaLogCallStack (pCdVinculo in ecadvinculo.cdvinculo%type default null) is
  vStrCallStack varchar2(2000);
  vCdVinculo ecadvinculo.cdvinculo%type;
  -- PRAGMA AUTONOMOUS_TRANSACTION;
begin

-- ESTE RETURN NÃO PODE SER EXCLUIDO, POR PADRAO DEVE FICAR ASSIM. APENAS COMENTAR A LINHA QDO FOR USAR O LOG CALLSTACK
return;
-- ESTE RETURN NÃO PODE SER EXCLUIDO, POR PADRAO DEVE FICAR ASSIM. APENAS COMENTAR A LINHA QDO FOR USAR O LOG CALLSTACK

/*if false then
  select SYS_CONTEXT('USERENV', 'OS_USER')
    into vStrCallStack
    from dual;
  if vStrCallStack != 'tiagopc' then
    return;
  end if;
else
  return;
end if; --*/

/*if pCdVinculo != 351743 then
return;
end if; --*/

  --pinserelogdebug('tpc', 'pGravaLogCallStack INI', XTMPAG_var.vgLogCallStack.Executor, XTMPAG_var.vgLogCallStack.Vinculos, XTMPAG_var.vgVinculo.cdvinculo);
  if XTMPAG_var.vgLogCallStack.Executor = 'NINGUEM' or XTMPAG_var.vgLogCallStack.Executor is null then
    return;
  else
    vCdVinculo := nvl(pCdVinculo, XTMPAG_var.vgVinculo.cdvinculo);
    if XTMPAG_var.vgLogCallStack.Executor like 'JOB%' then
      --pinserelogdebug('tpc', 'pGravaLogCallStack', pCdVinculo, XTMPAG_var.vgVinculo.cdvinculo, vCdVinculo);
      if XTMPAG_var.vgLogCallStack.Vinculos is null
         or instr(XTMPAG_var.vgLogCallStack.Vinculos, ','|| to_char(vCdVinculo) ||',') <= 0
      then
        return;
      end if;
    end if;
  end if;

  --dbms_output.put_line(DBMS_UTILITY.format_call_stack);
  vStrCallStack := replace(DBMS_UTILITY.format_call_stack, '----- PL/SQL Call Stack -----'|| chr(10));
  vStrCallStack := replace(vStrCallStack, '  object      line  object'|| chr(10));
  vStrCallStack := replace(vStrCallStack, '  handle    number  name'|| chr(10));
  vStrCallStack := regexp_replace(vStrCallStack, '.*anonymous block'|| chr(10));
  vStrCallStack := regexp_replace(vStrCallStack, '0x.+  ');
  vStrCallStack := regexp_replace(vStrCallStack, 'package body [A-Z|_]+\.');
  vStrCallStack := replace(vStrCallStack, '-- xtmpag_util.pGravaLOGCALLSTACK'|| chr(10));
  vStrCallStack := replace(vStrCallStack, 'XTMPAG_UTIL.PDEBUGCALCULO'|| chr(10));
  --  vStrCallStack := trim(vStrCallStack);
  --  vStrCallStack := replace(vStrCallStack, chr(10) || chr(10), '#');
  --  vStrCallStack := regexp_replace(vStrCallStack, '\r', '#');
  --  vStrCallStack := replace(vStrCallStack, chr(10), '#');
  --dbms_output.put_line(vStrCallStack);
  --return;
  --end if;

  if XTMPAG_var.vgLogCallStack.ExecucaoId <= 0 then
    select nvl(max(lc.exec_id), 0) + 1
      into XTMPAG_var.vgLogCallStack.ExecucaoId
      from log_callstack lc
     where lc.executor = XTMPAG_var.vgLogCallStack.Executor
       and (XTMPAG_var.vgFolha.cdfolhapagamento is null and lc.cdfolhapagamento is null
           or lc.cdfolhapagamento = XTMPAG_var.vgFolha.cdfolhapagamento)
       and (vCdVinculo is null and lc.cdvinculo is null
           or lc.cdvinculo = vCdVinculo);
  end if;

  insert into log_callstack values (
         s_log_callstack.nextval
       , XTMPAG_var.vgLogCallStack.Executor
       , sysdate
       , vStrCallStack
       , null
       , XTMPAG_var.vgFolha.cdfolhapagamento
       , vCdVinculo
       , XTMPAG_var.vgLogCallStack.ExecucaoId);
  commit;

end;

---------------------------------------------------------------------------------------------------------
procedure pAtivaLogHRV is

  vExecutor varchar2(30);
  vNumAux number;
  vObs varchar2(1000) := null;

  procedure pInsereExcecao is
  begin
    insert into log_hisrubvin (log_id, executor, date_time, obs)
      values (s_log_hisrubvin.nextval, vExecutor, sysdate, vObs);
  end;

begin

  begin
    vExecutor := SYS_CONTEXT('ctxGeral', 'logHRVExecutor');
  exception
  when others then
    vExecutor := null;
  end;

  if vExecutor is null then

    select count(*)
      into vNumAux
      from all_triggers t
     where t.TRIGGER_NAME = 'TPAGHISRUBVINLOG'
       and t.OWNER = 'SIGRH'
       and t.STATUS = 'ENABLED';

    if vNumAux > 0 then

      begin
        vExecutor := SYS_CONTEXT('USERENV', 'OS_USER');
        if    -- AGPE
              vExecutor in ('NTSIGRH-APP11$', 'NTSIGRH-APP12$' -- APLICACAO PRD
                          , 'NTSIGRH-APP13$', 'NTSIGRH-APP14$', 'NTSIGRH-APP15$')
           or vExecutor in ('NTSIGRH-APPH11$') -- APLICACAO HOM
           or vExecutor in ('NTSIGRH-QLD$') -- APLICACAO QLD
              -- MP
           or vExecutor in ('SIGRH-HML$') -- APLICACAO HOM
        then
          vExecutor := 'APLICACAO';
        elsif vExecutor in ('oradb', 'grid') then
          if sys_context('userenv', 'BG_JOB_ID') is not null then
            vExecutor := 'JOB';
          else
            vObs := 'OS_USER é '|| vExecutor ||' mas sem JOB';
            pInsereExcecao;
            vExecutor := 'NINGUEM';
          end if;
        elsif vExecutor in ('claudiakz', 'fabiovs', 'ibrowse_fmedeiros', 'luisfc', 'marcelob', 'silvioan', 'tiagopc', 'WS-CI001997') then
          null;
        elsif vExecutor in ('NTCIASC-DBATOOL$', 'SIGRHServicosAppPool') then
          vExecutor := 'NINGUEM';
        else
          vObs := 'Adicionar em XTMPAG_UTIL.pAtivaLogHRV: OS_USER '|| vExecutor;
          pInsereExcecao;
          vExecutor := 'NINGUEM';
        end if;
        select p.valor
          into vExecutor
          from log_param p
         where p.param = 'GRAVAR_LOG_HRV'
           and p.valor = vExecutor
           and p.ativo = 1;
        if vExecutor = 'JOB' then
          vExecutor := 'JOB '|| sys_context('userenv', 'BG_JOB_ID');
        end if;
      exception
      when others then
        vExecutor := 'NINGUEM';
      end; --*/
      --vExecutor := 'tiagopc';

    else
      vExecutor := 'NINGUEM';
    end if;

    setContextosGerais.logHRVExecutor(vExecutor);
  end if;

end;

---------------------------------------------------------------------------------------------------------
procedure pDesativaLogHRV is
begin
  setContextosGerais.logHRVExecutor(null);
end;

---------------------------------------------------------------------------------------------------------
procedure pAtivaTriggerLogHRV is
begin
  execute immediate 'alter trigger sigrh.tpaghisrubvinlog enable';
  execute immediate 'alter trigger sigrh.tpaghisrubrelvinlog enable';
end;

---------------------------------------------------------------------------------------------------------
procedure pDesativaTriggerLogHRV is
begin
  execute immediate 'alter trigger tpaghisrubvinlog disable';
  execute immediate 'alter trigger tpaghisrubrelvinlog disable';
end;

---------------------------------------------------------------------------------------------------------
procedure pDebugCalculo (pCdFolhaPagamento in epagfolhapagamento.cdfolhapagamento%type
                       , pCdVinculo in ecadvinculo.cdvinculo%type
                       , pNuMatricula in ecadvinculo.numatricula%type
                       , pNuSeqMatricula in ecadvinculo.nuseqmatricula%type
                       , pDtCalculo in out epagfolhapagamento.dtcalculo%type
                       , pFlCalculoDefinitivo in epagfolhapagamento.flcalculodefinitivo%type default 'N'
                       , pGravarLogHRV in boolean default false
                       , pExcluirLogHRV in boolean default false
                       , pGravarLogCallStack in pls_integer default 0
                       , pApenasExcluirHRV boolean default false
                       , pMsgRetorno out varchar2) is

  -- pCdFolhaPagamento    : obrigatorio
  -- pCdVinculo           : nao obrigatorio
  -- pNuMatricula         : nao obrigatorio
  -- pNuSeqMatricula      : nao obrigatorio
  -- pDtCalculo           : nao obrigatorio
  -- pFlCalculoDefinitivo : nao obrigatorio - S ou N
  -- pGravarLogHRV        : nao obrigatorio - 0 nao grava ou 1 grava na log_hisrubvin
  -- pExcluirLogHRV       : nao obrigatorio - 0 nao exclui ou 1 exclui da log_hisrubvin
  --                         tudo do respectivo folha/vinculo
  -- pApenasExcluirHRV    : nao obrigatorio - 0 nao exclui ou 1 exclui as rubricas do
  --                         contracheque, sem executar novo calculo.
  --                         Util pra saber se pCdFolhaPagamento e pCdVinculo vao
  --                         calculoar o contracheque certo.
  -- pMsgRetorno          : observacoes de retorno da procedure

  vCdVinculo ecadvinculo.cdvinculo%type;
  vcdmensagem integer;
  vdeparametros varchar2(2000);
  vDtCalculo epagfolhapagamento.dtcalculo%type;

  vCalculoRetorno XTMPAG_CAL.rCalculoRetorno;

begin

  select trunc(fp.dtcalculo)
    into vDtCalculo
    from epagfolhapagamento fp
   where fp.cdfolhapagamento = pCdFolhaPagamento;

  if pDtCalculo is not null then
    if pDtCalculo != vDtCalculo then
      pMsgRetorno := 'DATA INFORMADA É DIFERENTE DA DATA DE CALCULO DA FOLHA INFORMADA';
      return;
    end if;
  else
    pDtCalculo := vDtCalculo;
  end if;

  if pNuMatricula is not null then
    begin
      select distinct v.cdvinculo
        into vCdVinculo
        from ecadvinculo v, epagcapahistrubricavinculo c
       where v.cdvinculo = c.cdvinculo
         and c.cdfolhapagamento = pCdFolhaPagamento
         and v.numatricula = pNuMatricula
         and v.nuseqmatricula = pNuSeqMatricula;
    exception
    when no_data_found then
      pMsgRetorno := 'VINCULO NAO ENCONTRADO';
    when others then
      pMsgRetorno := 'MAIS DE UM VINCULO ENCONTRADO PARA A MATRICULA INFORMADA';
    end;
    if nvl(vCdVinculo, 0) <= 0 then
      return;
    end if;
  else
    vCdVinculo := pCdVinculo;
  end if;

  for rec in (
    select cdvinculo
      from (      select distinct hrv.cdvinculo
                    from epaghistoricorubricavinculo hrv
                   where hrv.cdfolhapagamento = pCdFolhaPagamento
                     and hrv.cdvinculo = nvl(vCdVinculo, hrv.cdvinculo)
           )
     --where rownum <= 10
    union
    select vCdVinculo cdvinculo from dual where vCdVinculo is not null
  ) loop

    if pExcluirLogHRV then
      delete log_hisrubvin d where d.cdfolhapagamento = pCdFolhaPagamento and d.cdvinculo = rec.cdvinculo;
    end if;

    delete epaghistoricorubricavinculo hrv where hrv.cdfolhapagamento = pCdFolhaPagamento and hrv.cdvinculo = rec.cdvinculo;
    --dbms_output.put_line(sql%rowcount);
    pMsgRetorno := to_char(sql%rowcount) ||' rubricas excluidas do contracheque antigo';
    delete epaghistoricorubricarelvinc hrv where hrv.cdfolhapagamento = pCdFolhaPagamento and hrv.cdvinculo = rec.cdvinculo;
    commit;
    if pApenasExcluirHRV then
      continue;
    end if;
    --return;

    if pGravarLogHRV then
      update log_param p set
             p.ativo = 1
       where p.param = 'GRAVAR_LOG_HRV'
         and p.valor = SYS_CONTEXT('USERENV', 'OS_USER');
      commit;
    end if;
    if pGravarLogCallStack > 0 then
      update log_param p set
             p.ativo = 1
       where p.param = 'GRAVAR_LOG_CALLSTACK'
         and p.valor = SYS_CONTEXT('USERENV', 'OS_USER');
      commit;
      if pGravarLogCallStack = 2 then
         pAtivaLogCallStack;
      end if;
      XTMPAG_var.vgFolha.cdfolhapagamento := pCdFolhaPagamento;
      XTMPAG_var.vgVinculo.cdvinculo := rec.cdvinculo;
    end if;

    XTMPAG_tar.pentrarcalculoindividual(pCdFolhaPagamento, rec.cdvinculo, trunc(pDtCalculo), pFlCalculoDefinitivo, 0, 'N', true, true, vCalculoRetorno);
    commit;

    if pGravarLogHRV then
      update log_param p set
             p.ativo = 0
       where p.param = 'GRAVAR_LOG_HRV'
         and p.valor = SYS_CONTEXT('USERENV', 'OS_USER');
      commit;
    end if;
    if pGravarLogCallStack > 0 then
      update log_param p set
             p.ativo = 0
       where p.param = 'GRAVAR_LOG_CALLSTACK'
         and p.valor = SYS_CONTEXT('USERENV', 'OS_USER');
      commit;
      if pGravarLogCallStack = 2 then
         pDesativaLogCallStack;
      end if;
    end if;

    dbms_output.put_line('1 - '|| vcdmensagem);
    dbms_output.put_line('2 - '|| vdeparametros);
    dbms_output.put_line(' ');

  end loop;

end;

---------------------------------------------------------------------------------------------------------
procedure pExcluiFolhaPagamento (pNuAnoMesReferencia epagfolhapagamento.nuanomesreferencia%type
                               /*, pStrCdFolhaPagamento in varchar2 default null*/) is
begin
  --pinserelogtst('XTMPAG_UTIL.pExcluiFolhaPagamento INI', null);
  for rFP in (
    select to_char(fp.cdfolhapagamento) cdfolhapagamento
      from epagfolhapagamento fp
     where fp.cdagrupamento = 1
       and fp.nuanomesreferencia = pNuAnoMesReferencia
       and fp.cdtipofolhapagamento = 2
       and fp.cdtipocalculo = 1
--and fp.cdorgao = 41
  ) loop
    begin
      execute immediate 'delete epaghistoricorubricavinculo d where d.cdfolhapagamento = '|| rFP.cdfolhapagamento;
      commit;
      execute immediate 'delete epaghistoricorubricarelvinc d where d.cdfolhapagamento = '|| rFP.cdfolhapagamento;
      commit;
      execute immediate 'delete epagcapahistrubricavinculo d where d.cdfolhapagamento = '|| rFP.cdfolhapagamento;
      commit; --*/
      execute immediate 'delete epagconferenciaempenho d where d.cdfolhapagamento = '|| rFP.cdfolhapagamento;
      commit;
      execute immediate 'delete epagfolhaconsolidadadetalhe d where d.cdfolhapagamento = '|| rFP.cdfolhapagamento;
      commit;
      execute immediate 'delete epagfolhaconsolidada d where d.cdfolhapagamento = '|| rFP.cdfolhapagamento;
      commit;
      execute immediate 'delete epaghistretificapagamento d where d.cdfolhapagamento = '|| rFP.cdfolhapagamento;
      commit;
      execute immediate 'delete epaghistrubricavincanulado d where d.cdfolhapagamento = '|| rFP.cdfolhapagamento;
      commit;
      execute immediate 'delete epagconferenciafolhapensao d where d.cdfolhapagamento = '|| rFP.cdfolhapagamento;
      commit;
      execute immediate 'delete epaglancomplementarcompetencia d where d.cdlancamentocomplementar in (select x.cdlancamentocomplementar from epaglancamentocomplementar x where x.cdfolhapagamento = '|| rFP.cdfolhapagamento ||')';
      commit;
      execute immediate 'delete epaglancamentocomplementar d where d.cdfolhapagamento = '|| rFP.cdfolhapagamento;
      commit;
      execute immediate 'delete epagconferenciacreditobancario d where d.cdfolhapagamento = '|| rFP.cdfolhapagamento;
      commit;
      execute immediate 'delete epagconferenciafolha d where d.cdfolhapagamento = '|| rFP.cdfolhapagamento;
      commit;
      execute immediate 'update epagfolhapagamento u set u.cdfolhavincsupl = null where u.cdfolhavincsupl = '|| rFP.cdfolhapagamento;
      execute immediate 'update epagfolhapagamento u set u.cdfolhaorigem = null where u.cdfolhaorigem = '|| rFP.cdfolhapagamento;
      execute immediate 'update epagfolhapagamento u set u.cdfolhasuplaglut = null where u.cdfolhasuplaglut = '|| rFP.cdfolhapagamento;
      execute immediate 'delete epagfolhapagamento d where d.cdfolhapagamento = '|| rFP.cdfolhapagamento;
      commit;
    exception
    when others then
      --pinserelogtst('XTMPAG_UTIL.pExcluiFolhaPagamento ERRO', rFP.cdfolhapagamento, sqlerrm);
      null;
    end;
  end loop;
  --pinserelogtst('XTMPAG_UTIL.pExcluiFolhaPagamento FIM', null);
end;

---------------------------------------------------------------------------------------------------------
procedure pExecAntesDoProcCalculo is
begin
  null;
  --if to_char(sysdate, 'ddhh24mi') > '190648' then
  --  commit;
  --end if;
end;

---------------------------------------------------------------------------------------------------------
procedure pProcessaIndividualParalelo (pExcluirCCAntes in boolean default false
                                     , pReprocessamentoIndividGeral in boolean default false) is
  vCdVinculo ecadvinculo.cdvinculo%type;
  vRowIdPI rowid;
  vDtCalculo epagfolhapagamento.dtcalculo%type;
  vCalculoRetorno XTMPAG_CAL.rCalculoRetorno;
begin

  /*insert into teste_tiago (id, momento) values (seq_teste_tiago.nextval, sysdate);
  commit;*/

  loop

    --insert into teste_tiago (id, momento, local_debug, param02) values (seq_teste_tiago.nextval, sysdate, 'inicio', to_char(systimestamp));
    begin
      select *
        into vCdVinculo, vRowIdPI
        from (select pi.cdvinculo, pi.rowid pi_rowid
                from eCalProcessamentoIndividual pi
               where pi.incalculado = 0
                 and rownum <= 1000
               order by DBMS_RANDOM.RANDOM --*/
               --order by pi.cdvinculo
             )
       where rownum <= 1;
    exception
    when others then
      exit;
    end;
    /*if vCdVinculo > 351743 then
      exit;
    end if;*/

    /*insert into teste_tiago (id, momento, local_debug, param01, param02) values (seq_teste_tiago.nextval, sysdate, 'lock', vCdVinculo, to_char(systimestamp));
    commit; --*/
    update eCalProcessamentoIndividual u
       set u.incalculado = 1 --decode(u.rowid, vRowIdPI, 1, 2)
     where u.incalculado = 0
       and (u.rowid = vRowIdPI
         /*or u.cdvinculo in (
             select v2.cdvinculo
               from ecadvinculo v1, ecadvinculo v2
              where v1.cdpessoa = v2.cdpessoa
                and v1.cdvinculo = vCdVinculo
                and v2.cdvinculo != v1.cdvinculo
                and exists (select 1
                              from ecalprocessamentoindividual pi
                             where pi.cdvinculo = v2.cdvinculo))*/);
    if sql%rowcount <= 0 then
      -- se outro job já pegou este contracheque pra calcular, pula..
      rollback; -- pra garantir unlock da tabela
      /*insert into teste_tiago (id, momento, local_debug, param01, param02) values (seq_teste_tiago.nextval, sysdate, 'unlock', vcdvinculo, to_char(systimestamp));
      commit;*/
      continue;
    else
      --insert into teste_tiago (id, momento, local_debug, param01, param02) values (seq_teste_tiago.nextval, sysdate, 'commit', vcdvinculo, to_char(systimestamp));
      commit;
    end if;
    --return;

    for rec in (
      select pi.*, pi.rowid pi_rowid
        from eCalProcessamentoIndividual pi
       where pi.incalculado = 1 --in (1, 2)
         and (pi.rowid = vRowIdPI
           /*or pi.cdvinculo in (
             select v2.cdvinculo
               from ecadvinculo v1, ecadvinculo v2
              where v1.cdpessoa = v2.cdpessoa
                and v1.cdvinculo = vCdVinculo
                and v2.cdvinculo != v1.cdvinculo
                and exists (select 1
                              from ecalprocessamentoindividual pi
                             where pi.cdvinculo = v2.cdvinculo))*/)
         --and pi.cdvinculo = 560474
       order by pi.inordem
    ) loop

      --if rec.incalculado = 2 then
        update eCalProcessamentoIndividual u
           set u.incalculado = 2
         where u.rowid = rec.pi_rowid;
        commit;
      --end if;

      rec.incalculado := 2;

      /*begin select sysdate into vDtCalculo from eCalProcessamentoIndividual pi where pi.rowid = rec.pi_rowid and pi.incalculado = 0; exception when no_data_found then continue; end;*/
      -----------------------------------------------------------------
      /*apex_util.pause(60);
      update eCalProcessamentoIndividual u
         set u.incalculado = 2
       where u.rowid = rec.pi_rowid;
      commit;
      continue; --*/

      if rec.cdfolhapagamento is null then
        begin
          select fp.cdfolhapagamento
            into rec.cdfolhapagamento
            from epagfolhapagamento fp
           where fp.cdorgao = rec.cdorgao
             and fp.nuanomesreferencia = rec.nuanomesreferencia
             and fp.cdtipofolhapagamento = rec.cdtipofolhapagamento
             and fp.cdtipocalculo = rec.cdtipocalculo
             and fp.nusequencialfolha = nvl(rec.nusequencialfolha, fp.nusequencialfolha);
        exception
        when others then
          rec.incalculado := -1;
        end;
        if nvl(rec.cdfolhapagamento, 0) > 0 then
          update eCalProcessamentoIndividual u
             set u.cdfolhapagamento = rec.cdfolhapagamento
           where u.rowid = rec.pi_rowid;
          commit;
        end if;
      end if;

      if rec.incalculado >= 0 then
        begin
          select fp.dtcalculo
            into vDtCalculo
            from epagfolhapagamento fp
           where fp.cdfolhapagamento = rec.cdfolhapagamento;
        exception
        when others then
          rec.incalculado := -2;
        end;
      end if;

      if rec.incalculado >= 0 then

        if pExcluirCCAntes then
          delete epaghistoricorubricavinculo d where d.cdfolhapagamento = rec.cdfolhapagamento and d.cdvinculo = rec.cdvinculo;
          delete epaghistoricorubricarelvinc d where d.cdfolhapagamento = rec.cdfolhapagamento and d.cdvinculo = rec.cdvinculo;
          delete epagcapahistrubricavinculo d where d.cdfolhapagamento = rec.cdfolhapagamento and d.cdvinculo = rec.cdvinculo;
        end if;

        rec.incalculado := 9;
        begin
          XTMPAG_tar.pentrarcalculoindividual(rec.cdfolhapagamento, rec.cdvinculo, trunc(vDtCalculo), nvl(rec.flcalculodefinitivo, 'N')
                                            , 0, 'N', false, false, vCalculoRetorno);
        exception
        when others then
          rec.incalculado := -3;
          dbms_output.put_line(sqlerrm); -- CRIAR OBS NA eCalProcessamentoIndividual
        end;

      end if;

      update eCalProcessamentoIndividual u
         set u.incalculado = rec.incalculado
       where u.rowid = rec.pi_rowid;
      commit;

      /*insert into teste_tiago (id, momento, local_debug, param01, param02) values (seq_teste_tiago.nextval, sysdate, 'fim calc', vcdvinculo, to_char(systimestamp));
      commit;*/

    end loop;
    --return;

    if pReprocessamentoIndividGeral then
      -- pra garantir que execute apenas 1 contracheque na sessao
      exit;
    end if;
  end loop;

end;

---------------------------------------------------------------------------------------------------------
procedure pCriaJobsProcIndividParalelo (pQtJobsParalelos in pls_integer
                                      , pExcluirCCAntes in boolean default false
                                      , pReprocessamentoIndividGeral in boolean default false) is
  vStrExcluirCCAntes varchar2(5);
  vStrReprocIndivGeral varchar2(5);
  vCntJobs pls_integer;
  idjob INTEGER;
begin

  begin
    if to_number(pQtJobsParalelos) <= 0 then
      return;
    end if;
  exception
  when others then
    return;
  end;

  if pExcluirCCAntes then
    vStrExcluirCCAntes := 'true';
  else
    vStrExcluirCCAntes := 'false';
  end if;
  if pReprocessamentoIndividGeral then
    vStrReprocIndivGeral := 'true';
  else
    vStrReprocIndivGeral := 'false';
  end if;

  vCntJobs := 0;
  loop
    sys.dbms_job.submit(idjob, 'begin XTMPAG_util.pprocessaindividualparalelo('|| vStrExcluirCCAntes ||', '|| vStrReprocIndivGeral ||'); end;', sysdate);
    commit;
    vCntJobs := vCntJobs + 1;
    if vCntJobs >= pQtJobsParalelos then
      exit;
    end if;
    dbms_session.sleep(0.1);
  end loop;

end;

---------------------------------------------------------------------------------------------------------
procedure pInsereLogTST /*(p_local_debug in varchar2, p_param01 in varchar2, p_param02 in varchar2 default null
                       , p_param03 in varchar2 default null, p_param04 in varchar2 default null
                       , p_param05 in varchar2 default null, p_param06 in varchar2 default null)*/ IS
  --vAux varchar2(1000);
  PRAGMA AUTONOMOUS_TRANSACTION;
begin
--return;
null;
/*
    --if SYS_CONTEXT('USERENV', 'OS_USER') = 'tiagopc' then
      insert into sigrh.teste_tiago (id, momento, local_debug, param01
           , param02, param03, param04, param05, param06)
--           , param10)
        values (seq_teste_tiago.nextval, sysdate, p_local_debug, p_param01
           , p_param02, p_param03, p_param04, p_param05, p_param06);
--           , DBMS_UTILITY.format_call_stack);
      commit;
    --end if;
*/
exception
when others then
null;
/*  vAux := sqlerrm;
  insert into sigrh.teste_tiago (id, momento, local_debug, param01, param02)
    values (seq_teste_tiago.nextval, sysdate, p_local_debug, SYS_CONTEXT('USERENV', 'OS_USER'), vAux);
  commit; */
end;

---------------------------------------------------------------------------------------------------------
procedure pInterrompeProcIndividParalelo is
  vCntJobs pls_integer;
  vCntLoop pls_integer;
begin

  update eCalProcessamentoIndividual u
     set u.incalculado = 99
   where u.incalculado = 0;
  commit;

  vCntLoop := 0;
  loop
    select count(*)
      into vCntJobs
      from eCalProcessamentoIndividual pi
     where pi.incalculado between 1 and 8;
    vCntLoop := vCntLoop + 1;
    if vCntJobs <= 0 or vCntLoop >= 120 then -- No maximo 2min aguardando. Mais do que isso pode significar que tem algum job travado.
      exit;
    end if;
    dbms_session.sleep(1);
  end loop;

  update eCalProcessamentoIndividual u
     set u.incalculado = 0
   where u.incalculado = 99;
  commit;
end;

---------------------------------------------------------------------------------------------------------
function fQtdePessoasCalculadas (pCdHistoricoParamCalculo in epaghistoricoparamcalculo.cdhistoricoparamcalculo%type)
  return pls_integer
is
  vQtdePessoasCalculadas pls_integer;
begin
  select sum(hpco.qtpessoascalculadas)
    into vQtdePessoasCalculadas
    from epaghistoricoparamcalculoorgao hpco
   where hpco.cdhistoricoparamcalculo = pCdHistoricoParamCalculo;
  return vQtdePessoasCalculadas;
end;
---------------------------------------------------------------------------------------------------------
procedure pVerLogCallStack (pExecutor in varchar2, pCdFolhaPagamento in number, pCdVinculo in number, pExecucaoId in pls_integer default 1) is

  p pls_integer;
  c pls_integer;
  b pls_integer;

  vMetodo varchar2(100);
  vCallStackMae varchar2(1000);
  vstr varchar2(100) := '                                                ';
  vExecucaoId pls_integer;

begin

  vExecucaoId := pExecucaoId;
  if nvl(vExecucaoId, 0) <= 0 then
    vExecucaoId := 1;
  end if;

  for rec in (
    select callstack, rownum rn
      from (select cs.callstack, rownum rn
              from log_callstack cs
             where cs.executor = nvl(pExecutor, cs.executor)
               and (cs.cdfolhapagamento = pCdFolhaPagamento or (pCdFolhaPagamento is null and cs.cdfolhapagamento is null))
               and (cs.cdvinculo = pCdVinculo or (pCdVinculo is null and cs.cdvinculo is null))
               and cs.exec_id = vExecucaoId
             order by cs.log_id)
  ) loop

    vMetodo := substr(rec.callstack, 1, instr(rec.callstack, chr(10)) - 1);
    vCallStackMae := substr(rec.callstack, instr(rec.callstack, chr(10)) + 1);
    --vCallStackMae := substr(vCallStackMae, 1, instr(rec.callstack, chr(10)) - 1);

    if rec.rn = 1 then
      b := length(regexp_replace(regexp_replace(rec.callstack, chr(10), '#'), '[^#]', ''));
    end if;

    p := 0;
    c := b * -1;
    loop

      p := instr(rec.callstack, chr(10), p + 1);
      if p = 0 then
        exit;
      end if;
      c := c + 1;

    end loop;

    dbms_output.put_line(substr(vstr, 1, c) || vMetodo);

  end loop;
end;

---------------------------------------------------------------------------------------------------------
procedure pEmpProcNomeTmp (

  -- aguardando definicao de nome pela Claudia
  --  referente a primeira consulta contida na documentacao
  --    Procedimentos para solucionar problemas na geracao dos arquivos de empenho
  --    https://docs.google.com/document/d/1UWQ8Cz5PzB3aOzN6IKvEhlBhyNhSyHLjA9HjR4AJq40/edit

  pCdCreditoBancario in epaghistoricoempenhorubrica.cdcreditobancario%type,
  pNuRubrica in epagrubrica.nurubrica%type,
  pNuUnidadeOrcamentaria in epaghistoricoempenhorubrica.nuunidadeorcamentaria%type default 41012,
  pCdAgrupamento ecadagrupamento.cdagrupamento%type default 1,
  Resultado out Types.ref_cursor) is
begin
  Open Resultado For
  SELECT *
    FROM epaghistoricoempenhorubrica x
   WHERE x.cdcreditobancario = pCdCreditoBancario
     AND x.nuunidadeorcamentaria = pNuUnidadeOrcamentaria
     AND x.cdrubricaagrupamento =
       (SELECT cdrubricaagrupamento
          FROM epagrubricaagrupamento ra
         INNER JOIN epagrubrica r
            ON r.cdrubrica = ra.cdrubrica
           AND r.nurubrica = pNuRubrica
           AND r.cdtiporubrica = 1
         WHERE ra.cdagrupamento = pCdAgrupamento);
end;

---------------------------------------------------------------------------------------------------------
function pEmpRubricaSemElementoDespesa (
  pCdOrgao ecadorgao.cdorgao%type,
  pNuMesReferencia epagfolhapagamento.numesreferencia%type,
  pNuAnoReferencia epagfolhapagamento.nuanoreferencia%type,
  pCdTipoFolhaPagamento epagfolhapagamento.cdtipofolhapagamento%type,
  pCdTipoCalculo epagfolhapagamento.cdtipocalculo%type,
  pNuSequencialFolha epagfolhapagamento.nusequencialfolha%type,
  Resultado out Types.ref_cursor) return pls_integer
is
  vCnt pls_integer;
begin

  -- se alterar esta query, alterar a do cursor tambem
  SELECT count(*)
    into vCnt
    FROM EPAGHISTORICORUBRICAVINCULO PAGA20
   INNER JOIN EPAGFOLHAPAGAMENTO PAGA16
      ON PAGA20.CdFolhaPagamento = PAGA16.CdFolhaPagamento
   INNER JOIN EPAGRUBRICAAGRUPAMENTO  PAGA34
      ON PAGA20.CdRubricaAgrupamento = PAGA34.CdRubricaAgrupamento
   INNER JOIN EPAGRUBRICA PAGA29
      ON PAGA34.CdRubrica = PAGA29.CdRubrica
   WHERE PAGA16.CdOrgao = pCdOrgao
     AND PAGA16.NuMesReferencia = pNuMesReferencia
     AND PAGA16.NuAnoReferencia = pNuAnoReferencia
     AND PAGA16.CdTipoFolhaPagamento = pCdTipoFolhaPagamento
     AND PAGA16.CdTipoCalculo = pCdTipoCalculo
     AND PAGA16.NuSequencialFolha = pNuSequencialFolha
     AND PAGA29.NuElemDespesaAtivo IS NULL
     AND PAGA29.NuElemDespesaInativo IS NULL
     AND PAGA29.CdConsignataria IS NULL
     AND PAGA29.NuOutraConsignataria IS NULL
     AND PAGA29.CdTipoRubrica <> 9;

  if vCnt > 0 then
    -- se alterar esta query, alterar a do count tambem
    Open Resultado For
    SELECT LPAD(PAGA29.CdTipoRubrica, 2, '0') || '-' ||
           LPAD(PAGA29.NuRubrica, 4, '0') AS RUB
      FROM EPAGHISTORICORUBRICAVINCULO PAGA20
     INNER JOIN EPAGFOLHAPAGAMENTO PAGA16
        ON PAGA20.CdFolhaPagamento = PAGA16.CdFolhaPagamento
     INNER JOIN EPAGRUBRICAAGRUPAMENTO  PAGA34
        ON PAGA20.CdRubricaAgrupamento = PAGA34.CdRubricaAgrupamento
     INNER JOIN EPAGRUBRICA PAGA29
        ON PAGA34.CdRubrica = PAGA29.CdRubrica
     WHERE PAGA16.CdOrgao = pCdOrgao
       AND PAGA16.NuMesReferencia = pNuMesReferencia
       AND PAGA16.NuAnoReferencia = pNuAnoReferencia
       AND PAGA16.CdTipoFolhaPagamento = pCdTipoFolhaPagamento
       AND PAGA16.CdTipoCalculo = pCdTipoCalculo
       AND PAGA16.NuSequencialFolha = pNuSequencialFolha
       AND PAGA29.NuElemDespesaAtivo IS NULL
       AND PAGA29.NuElemDespesaInativo IS NULL
       AND PAGA29.CdConsignataria IS NULL
       AND PAGA29.NuOutraConsignataria IS NULL
       AND PAGA29.CdTipoRubrica <> 9;
  end if;
  return vCnt;

exception
when others then
  return -1;
end;

---------------------------------------------------------------------------------------------------------
function pEmpVerLiquidNegativoFolNormal (
  pNuAnoMesReferencia epagfolhapagamento.nuanomesreferencia%type,
  pCdOrgao ecadorgao.cdorgao%type,
  pCdTipoFolhaPagamento epagfolhapagamento.cdtipofolhapagamento%type,
  pCdAgrupamento ecadagrupamento.cdagrupamento%type default 1,
  Resultado out Types.ref_cursor) return pls_integer
is
  vCnt pls_integer;
begin

  -- se alterar esta query, alterar a do cursor tambem
  SELECT count(*)
    into vCnt
    FROM (SELECT hrv.cdfolhapagamento,
                 hrv.cdvinculo,
                 SUM(hrv.vlpagamento) v9901
            FROM epaghistoricorubricavinculo hrv
           WHERE hrv.cdfolhapagamento IN
                 (SELECT p.cdfolhapagamento
                    FROM epagfolhapagamento p
                   WHERE p.nuanomesreferencia = pNuAnoMesReferencia
                     AND p.cdorgao = pCdOrgao
                     AND p.cdtipofolhapagamento = pCdTipoFolhaPagamento
                     AND p.cdtipocalculo = 1
                     AND p.flcalculodefinitivo = 'S')
             AND hrv.cdrubricaagrupamento =
                 (SELECT ra.cdrubricaagrupamento
                    FROM epagrubricaagrupamento ra
                   WHERE ra.cdagrupamento = pCdAgrupamento
                     AND ra.cdrubrica =
                         (SELECT r.cdrubrica
                            FROM epagrubrica r
                           WHERE r.cdtiporubrica = 9
                             AND r.nurubrica = 901))
           GROUP BY hrv.cdfolhapagamento, hrv.cdvinculo) a
   INNER JOIN (SELECT hrv.cdfolhapagamento,
                      hrv.cdvinculo,
                      SUM(hrv.vlpagamento) v9909
                 FROM epaghistoricorubricavinculo hrv
                WHERE hrv.cdfolhapagamento IN
                      (SELECT p.cdfolhapagamento
                         FROM epagfolhapagamento p
                        WHERE p.nuanomesreferencia = pNuAnoMesReferencia
                          AND p.cdorgao = pCdOrgao
                          AND p.cdtipofolhapagamento = pCdTipoFolhaPagamento
                          AND p.cdtipocalculo = 1
                          AND p.flcalculodefinitivo = 'S')
                  AND hrv.cdrubricaagrupamento =
                      (SELECT ra.cdrubricaagrupamento
                         FROM epagrubricaagrupamento ra
                        WHERE ra.cdagrupamento = pCdAgrupamento
                          AND ra.cdrubrica =
                              (SELECT r.cdrubrica
                                 FROM epagrubrica r
                                WHERE r.cdtiporubrica = 9
                                  AND r.nurubrica = 909))
                GROUP BY hrv.cdfolhapagamento, hrv.cdvinculo) b
      ON a.cdvinculo = b.cdvinculo
   WHERE b.v9909 > a.v9901;

  if vCnt > 0 then
    -- se alterar esta query, alterar a do count tambem
    Open Resultado For
    SELECT *
      FROM (SELECT hrv.cdfolhapagamento,
                   hrv.cdvinculo,
                   SUM(hrv.vlpagamento) v9901
              FROM epaghistoricorubricavinculo hrv
             WHERE hrv.cdfolhapagamento IN
                   (SELECT p.cdfolhapagamento
                      FROM epagfolhapagamento p
                     WHERE p.nuanomesreferencia = pNuAnoMesReferencia
                       AND p.cdorgao = pCdOrgao
                       AND p.cdtipofolhapagamento = pCdTipoFolhaPagamento
                       AND p.cdtipocalculo = 1
                       AND p.flcalculodefinitivo = 'S')
               AND hrv.cdrubricaagrupamento =
                   (SELECT ra.cdrubricaagrupamento
                      FROM epagrubricaagrupamento ra
                     WHERE ra.cdagrupamento = pCdAgrupamento
                       AND ra.cdrubrica =
                           (SELECT r.cdrubrica
                              FROM epagrubrica r
                             WHERE r.cdtiporubrica = 9
                               AND r.nurubrica = 901))
             GROUP BY hrv.cdfolhapagamento, hrv.cdvinculo) a
     INNER JOIN (SELECT hrv.cdfolhapagamento,
                        hrv.cdvinculo,
                        SUM(hrv.vlpagamento) v9909
                   FROM epaghistoricorubricavinculo hrv
                  WHERE hrv.cdfolhapagamento IN
                        (SELECT p.cdfolhapagamento
                           FROM epagfolhapagamento p
                          WHERE p.nuanomesreferencia = pNuAnoMesReferencia
                            AND p.cdorgao = pCdOrgao
                            AND p.cdtipofolhapagamento = pCdTipoFolhaPagamento
                            AND p.cdtipocalculo = 1
                            AND p.flcalculodefinitivo = 'S')
                    AND hrv.cdrubricaagrupamento =
                        (SELECT ra.cdrubricaagrupamento
                           FROM epagrubricaagrupamento ra
                          WHERE ra.cdagrupamento = pCdAgrupamento
                            AND ra.cdrubrica =
                                (SELECT r.cdrubrica
                                   FROM epagrubrica r
                                  WHERE r.cdtiporubrica = 9
                                    AND r.nurubrica = 909))
                  GROUP BY hrv.cdfolhapagamento, hrv.cdvinculo) b
        ON a.cdvinculo = b.cdvinculo
     WHERE b.v9909 > a.v9901;
  end if;
  return vCnt;

exception
when others then
  return -1;
end;

---------------------------------------------------------------------------------------------------------
function pEmpVerLiquidNegativoCapaCC (
  pCdFolhaPagamento epagfolhapagamento .cdfolhapagamento%type,
  Resultado out Types.ref_cursor) return pls_integer
is
  vCnt pls_integer;
begin
  -- se alterar esta query, alterar a do cursor tambem
  SELECT count(*)
    into vCnt
    FROM (SELECT SUM(CAPA.VLPROVENTOS - CAPA.VLDESCONTOS) AS PRODESC,
                 SUM(CAPA.VLCREDITO) AS CRED, CDVINCULO
            FROM EPAGCAPAHISTRUBRICAVINCULO CAPA
           WHERE CAPA.CDFOLHAPAGAMENTO = pCdFolhaPagamento
             AND CAPA.FLATIVO = 'S'
           GROUP BY CDVINCULO) A
   INNER JOIN ecadvinculo v
      ON v.cdvinculo = a.cdvinculo
   INNER JOIN ecadpessoa p
      ON p.cdpessoa = v.cdpessoa
   INNER JOIN ecadhistorgao ho
      ON ho.cdorgao = v.cdorgao
      AND ho.dtfimvigencia IS NULL
   WHERE A.PRODESC <> A.CRED;

  if vCnt > 0 then
    -- se alterar esta query, alterar a do count tambem
    Open Resultado For
    SELECT ho.cdorgaosirh, ho.sgorgao
         , pkgutil.FFORMATAMATRICULA(v.numatricula, v.nudvmatricula, v.nuseqmatricula)
         , p.nmpessoa, a.prodesc, a.cred, a.cdvinculo
      FROM (SELECT SUM(CAPA.VLPROVENTOS - CAPA.VLDESCONTOS) AS PRODESC,
                   SUM(CAPA.VLCREDITO) AS CRED, CDVINCULO
              FROM EPAGCAPAHISTRUBRICAVINCULO CAPA
             WHERE CAPA.CDFOLHAPAGAMENTO = pCdFolhaPagamento
               AND CAPA.FLATIVO = 'S'
             GROUP BY CDVINCULO) A
     INNER JOIN ecadvinculo v
        ON v.cdvinculo = a.cdvinculo
     INNER JOIN ecadpessoa p
        ON p.cdpessoa = v.cdpessoa
     INNER JOIN ecadhistorgao ho
        ON ho.cdorgao = v.cdorgao
        AND ho.dtfimvigencia IS NULL
     WHERE A.PRODESC <> A.CRED;
  end if;
  return vCnt;

exception
when others then
  return -1;
end;

---------------------------------------------------------------------------------------------------------
function pEmpVerLiquidNegativoPenAlimen (
  pNuAnoMesReferencia epagfolhapagamento.nuanomesreferencia%type,
  pCdOrgao ecadorgao.cdorgao%type,
  pCdTipoFolhaPagamento epagfolhapagamento.cdtipofolhapagamento%type,
  pCdAgrupamento ecadagrupamento.cdagrupamento%type default 1,
  Resultado out Types.ref_cursor) return pls_integer
is
  vCnt pls_integer;
begin
  -- se alterar esta query, alterar a do cursor tambem
  SELECT count(*)
    into vCnt
    FROM (SELECT hrv.cdvinculo,
                 hrv.nusufixorubrica,
                 SUM(hrv.vlpagamento) v4586
            FROM epaghistoricorubricavinculo hrv
           WHERE hrv.cdfolhapagamento IN
                 (SELECT p.cdfolhapagamento
                    FROM epagfolhapagamento p
                   WHERE p.nuanomesreferencia = pNuAnoMesReferencia
                     AND p.cdorgao = pCdOrgao
                     AND p.cdtipofolhapagamento = pCdTipoFolhaPagamento
                     AND p.cdtipocalculo = 1
                     AND p.flcalculodefinitivo = 'S')
             AND hrv.cdrubricaagrupamento IN
                 (SELECT ra.cdrubricaagrupamento
                    FROM epagrubricaagrupamento ra
                   WHERE ra.cdagrupamento = pCdAgrupamento
                     AND ra.flpensaoalimenticia = 'S'
                     AND ra.cdrubrica IN
                         (SELECT r.cdrubrica
                            FROM epagrubrica r
                           WHERE r.cdtiporubrica = 4))
           GROUP BY hrv.cdvinculo, hrv.nusufixorubrica) a
    LEFT JOIN (SELECT hrv.cdvinculo,
                      hrv.nusufixorubrica,
                      SUM(hrv.vlpagamento) v5586
                 FROM epaghistoricorubricavinculo hrv
                WHERE hrv.cdfolhapagamento IN
                      (SELECT p.cdfolhapagamento
                         FROM epagfolhapagamento p
                        WHERE p.nuanomesreferencia = pNuAnoMesReferencia
                          AND p.cdorgao = pCdOrgao
                          AND p.cdtipofolhapagamento = pCdTipoFolhaPagamento
                          AND p.cdtipocalculo = 1
                          AND p.flcalculodefinitivo = 'S')
                  AND hrv.cdrubricaagrupamento IN
                      (SELECT ra.cdrubricaagrupamento
                         FROM epagrubricaagrupamento ra
                        WHERE ra.cdagrupamento = pCdAgrupamento
                          AND ra.flpensaoalimenticia = 'S'
                          AND ra.cdrubrica IN
                              (SELECT r.cdrubrica
                                 FROM epagrubrica r
                                WHERE r.cdtiporubrica IN (5, 6)))
                GROUP BY hrv.cdvinculo, hrv.nusufixorubrica) b
      ON a.cdvinculo = b.cdvinculo
     AND a.nusufixorubrica = b.nusufixorubrica
   WHERE a.v4586 > b.v5586
      OR b.v5586 IS NULL;

  if vCnt > 0 then
    -- se alterar esta query, alterar a do count tambem
    Open Resultado For
    SELECT *
      FROM (SELECT hrv.cdvinculo,
                   hrv.nusufixorubrica,
                   SUM(hrv.vlpagamento) v4586
              FROM epaghistoricorubricavinculo hrv
             WHERE hrv.cdfolhapagamento IN
                   (SELECT p.cdfolhapagamento
                      FROM epagfolhapagamento p
                     WHERE p.nuanomesreferencia = pNuAnoMesReferencia
                       AND p.cdorgao = pCdOrgao
                       AND p.cdtipofolhapagamento = pCdTipoFolhaPagamento
                       AND p.cdtipocalculo = 1
                       AND p.flcalculodefinitivo = 'S')
               AND hrv.cdrubricaagrupamento IN
                   (SELECT ra.cdrubricaagrupamento
                      FROM epagrubricaagrupamento ra
                     WHERE ra.cdagrupamento = pCdAgrupamento
                       AND ra.flpensaoalimenticia = 'S'
                       AND ra.cdrubrica IN
                           (SELECT r.cdrubrica
                              FROM epagrubrica r
                             WHERE r.cdtiporubrica = 4))
             GROUP BY hrv.cdvinculo, hrv.nusufixorubrica) a
      LEFT JOIN (SELECT hrv.cdvinculo,
                        hrv.nusufixorubrica,
                        SUM(hrv.vlpagamento) v5586
                   FROM epaghistoricorubricavinculo hrv
                  WHERE hrv.cdfolhapagamento IN
                        (SELECT p.cdfolhapagamento
                           FROM epagfolhapagamento p
                          WHERE p.nuanomesreferencia = pNuAnoMesReferencia
                            AND p.cdorgao = pCdOrgao
                            AND p.cdtipofolhapagamento = pCdTipoFolhaPagamento
                            AND p.cdtipocalculo = 1
                            AND p.flcalculodefinitivo = 'S')
                    AND hrv.cdrubricaagrupamento IN
                        (SELECT ra.cdrubricaagrupamento
                           FROM epagrubricaagrupamento ra
                          WHERE ra.cdagrupamento = pCdAgrupamento
                            AND ra.flpensaoalimenticia = 'S'
                            AND ra.cdrubrica IN
                                (SELECT r.cdrubrica
                                   FROM epagrubrica r
                                  WHERE r.cdtiporubrica IN (5, 6)))
                  GROUP BY hrv.cdvinculo, hrv.nusufixorubrica) b
        ON a.cdvinculo = b.cdvinculo
       AND a.nusufixorubrica = b.nusufixorubrica
     WHERE a.v4586 > b.v5586
        OR b.v5586 IS NULL;
  end if;
  return vCnt;

exception
when others then
  return -1;
end;

---------------------------------------------------------------------------------------------------------
function pEmpServsPensaoNaoEstaoRelCred (
  pCdCreditoBancario in epaghistoricoempenhorubrica.cdcreditobancario%type,
  pNuAnoMesReferencia epagfolhapagamento.nuanomesreferencia%type,
  pCdOrgao ecadorgao.cdorgao%type,
  pCdTipoFolhaPagamento epagfolhapagamento.cdtipofolhapagamento%type,
  pCdTipoCalculo epagfolhapagamento.cdtipocalculo%type,
  Resultado out Types.ref_cursor) return pls_integer
is
  vCnt pls_integer;
begin
  -- se alterar esta query, alterar a do cursor tambem
  SELECT count(*)
    into vCnt
    FROM epaghistoricorubricavinculo hrv
   INNER JOIN epagcapahistrubricavinculo cp
      ON cp.cdvinculo = hrv.cdvinculo
     AND cp.cdfolhapagamento = hrv.cdfolhapagamento
     AND cp.flativo = 'N'
     AND cp.vlcredito <> 0
   WHERE hrv.cdfolhapagamento IN
         (SELECT p.cdfolhapagamento
            FROM epagfolhapagamento p
           WHERE p.nuanomesreferencia = pNuAnoMesReferencia
             AND p.cdorgao = pCdOrgao
             AND p.cdtipofolhapagamento = pCdTipoFolhaPagamento
             AND p.cdtipocalculo = pCdTipoCalculo
             AND p.flcalculodefinitivo = 'S')
     AND hrv.cdrubricaagrupamento IN (11182 /*24918*/)
     AND hrv.cdvinculo NOT IN
         (SELECT x.cdvinculo
            FROM epagcapacreditobancario x
           WHERE x.cdcreditobancario = pCdCreditoBancario);

  if vCnt > 0 then
    -- se alterar esta query, alterar a do count tambem
    Open Resultado For
    SELECT hrv.cdfolhapagamento, hrv.cdvinculo, hrv.vlpagamento
      FROM epaghistoricorubricavinculo hrv
     INNER JOIN epagcapahistrubricavinculo cp
        ON cp.cdvinculo = hrv.cdvinculo
       AND cp.cdfolhapagamento = hrv.cdfolhapagamento
       AND cp.flativo = 'N'
       AND cp.vlcredito <> 0
     WHERE hrv.cdfolhapagamento IN
           (SELECT p.cdfolhapagamento
              FROM epagfolhapagamento p
             WHERE p.nuanomesreferencia = pNuAnoMesReferencia
               AND p.cdorgao = pCdOrgao
               AND p.cdtipofolhapagamento = pCdTipoFolhaPagamento
               AND p.cdtipocalculo = pCdTipoCalculo
               AND p.flcalculodefinitivo = 'S')
       AND hrv.cdrubricaagrupamento IN (11182 /*24918*/)
       AND hrv.cdvinculo NOT IN
           (SELECT x.cdvinculo
              FROM epagcapacreditobancario x
             WHERE x.cdcreditobancario = pCdCreditoBancario);
  end if;
  return vCnt;

exception
when others then
  return -1;
end;

---------------------------------------------------------------------------------------------------------
function pEmpExisteRubLiquidoNegativo (
  pNuAnoMesReferencia epagfolhapagamento.nuanomesreferencia%type,
  pCdTipoFolhaPagamento epagfolhapagamento.cdtipofolhapagamento%type,
  Resultado out Types.ref_cursor) return pls_integer
is
  vCnt pls_integer;
begin
  -- se alterar esta query, alterar a do cursor tambem
  SELECT count(*)
    into vCnt
    FROM epagfolhapagamento p
   INNER JOIN epaghistoricorubricavinculo hrv
      ON hrv.cdfolhapagamento = p.cdfolhapagamento
   INNER JOIN epagrubricaagrupamento ra
      ON ra.cdrubricaagrupamento = hrv.cdrubricaagrupamento
   INNER JOIN epagrubrica r
      ON r.cdrubrica = ra.cdrubrica
     AND r.cdtiporubrica = 1
     AND r.nurubrica = 9000
   INNER JOIN vcadorgaoultimavigencia o
     ON o.CDORGAO = p.cdorgao
   WHERE p.nuanomesreferencia = pNuAnoMesReferencia
     --AND p.cdorgao = 41
     AND p.cdtipofolhapagamento = pCdTipoFolhaPagamento
     AND p.flcalculodefinitivo = 'S';

  if vCnt > 0 then
    -- se alterar esta query, alterar a do count tambem
    Open Resultado For
    SELECT o.CDORGAOSIRH, hrv.cdvinculo, hrv.vlpagamento
      FROM epagfolhapagamento p
     INNER JOIN epaghistoricorubricavinculo hrv
        ON hrv.cdfolhapagamento = p.cdfolhapagamento
     INNER JOIN epagrubricaagrupamento ra
        ON ra.cdrubricaagrupamento = hrv.cdrubricaagrupamento
     INNER JOIN epagrubrica r
        ON r.cdrubrica = ra.cdrubrica
       AND r.cdtiporubrica = 1
       AND r.nurubrica = 9000
     INNER JOIN vcadorgaoultimavigencia o
       ON o.CDORGAO = p.cdorgao
     WHERE p.nuanomesreferencia = pNuAnoMesReferencia
       --AND p.cdorgao = 41
       AND p.cdtipofolhapagamento = pCdTipoFolhaPagamento
       AND p.flcalculodefinitivo = 'S';
  end if;
  return vCnt;

exception
when others then
  return -1;
end;

---------------------------------------------------------------------------------------------------------
function pEmpVerDadosBancarDuplicados (
  pNuAnoMesReferencia epagfolhapagamento.nuanomesreferencia%type,
  pCdTipoFolhaPagamento epagfolhapagamento.cdtipofolhapagamento%type,
  Resultado out Types.ref_cursor) return pls_integer
is
  vCnt pls_integer;
begin
  -- se alterar esta query, alterar a do cursor tambem
  WITH capa AS
   (SELECT *
      FROM epagcapahistrubricavinculo c
     WHERE c.cdfolhapagamento IN
           (SELECT p.cdfolhapagamento
              FROM epagfolhapagamento p
             WHERE p.nuanomesreferencia = pNuAnoMesReferencia
               AND p.cdtipocalculo = 1
               AND p.cdtipofolhapagamento = pCdTipoFolhaPagamento
               AND p.flcalculodefinitivo = 'S'))
  SELECT count(DISTINCT s.cdvinculo)
    into vCnt
    FROM capa a
    LEFT JOIN (SELECT cdvinculo, dtiniciovigencia
                 FROM (SELECT x.cdvinculo, x.dtiniciovigencia, COUNT(*)
                         FROM ecadhistdadosbancariosvinculo x
                        WHERE x.flanulado = 'N'
                          AND x.dtiniciovigencia =
                              (SELECT MAX(dtiniciovigencia)
                                 FROM ecadhistdadosbancariosvinculo z
                                WHERE z.cdvinculo = x.cdvinculo
                                  AND z.flanulado = 'N')
                        GROUP BY x.cdvinculo, x.dtiniciovigencia
                       HAVING COUNT(*) > 1)) s
      ON s.cdvinculo = a.cdvinculo
   WHERE (a.vlproventos <> 0 OR a.vlproventos IS NOT NULL);

  if vCnt > 0 then
    -- se alterar esta query, alterar a do count tambem
    Open Resultado For
    WITH capa AS
     (SELECT *
        FROM epagcapahistrubricavinculo c
       WHERE c.cdfolhapagamento IN
             (SELECT p.cdfolhapagamento
                FROM epagfolhapagamento p
               WHERE p.nuanomesreferencia = pNuAnoMesReferencia
                 AND p.cdtipocalculo = 1
                 AND p.cdtipofolhapagamento = pCdTipoFolhaPagamento
                 AND p.flcalculodefinitivo = 'S'))
    SELECT DISTINCT s.cdvinculo
      FROM capa a
      LEFT JOIN (SELECT cdvinculo, dtiniciovigencia
                   FROM (SELECT x.cdvinculo, x.dtiniciovigencia, COUNT(*)
                           FROM ecadhistdadosbancariosvinculo x
                          WHERE x.flanulado = 'N'
                            AND x.dtiniciovigencia =
                                (SELECT MAX(dtiniciovigencia)
                                   FROM ecadhistdadosbancariosvinculo z
                                  WHERE z.cdvinculo = x.cdvinculo
                                    AND z.flanulado = 'N')
                          GROUP BY x.cdvinculo, x.dtiniciovigencia
                         HAVING COUNT(*) > 1)) s
        ON s.cdvinculo = a.cdvinculo
     WHERE (a.vlproventos <> 0 OR a.vlproventos IS NOT NULL);
  end if;
  return vCnt;

exception
when others then
  return -1;
end;

---------------------------------------------------------------------------------------------------------
function pEmpVerVinculosSemDadosBancar (
  pNuAnoMesReferencia epagfolhapagamento.nuanomesreferencia%type,
  pCdTipoFolhaPagamento epagfolhapagamento.cdtipofolhapagamento%type,
  Resultado out Types.ref_cursor) return pls_integer
is
  vCnt pls_integer;
begin
  -- se alterar esta query, alterar a do cursor tambem
  SELECT count(*)
    into vCnt
    FROM epagcapahistrubricavinculo c
   WHERE c.cdfolhapagamento IN
         (SELECT p.cdfolhapagamento
            FROM epagfolhapagamento p
           WHERE p.nuanomesreferencia = pNuAnoMesReferencia
             AND p.cdtipocalculo = 1
             AND p.cdtipofolhapagamento = pCdTipoFolhaPagamento
             AND p.flcalculodefinitivo = 'S')
    AND c.cdvinculo NOT IN (SELECT v.cdvinculo FROM ecadhistdadosbancariosvinculo v)
    AND (c.vlproventos <> 0 OR c.vlproventos IS NULL);

  if vCnt > 0 then
    -- se alterar esta query, alterar a do count tambem
    Open Resultado For
    SELECT *
      FROM epagcapahistrubricavinculo c
     WHERE c.cdfolhapagamento IN
           (SELECT p.cdfolhapagamento
              FROM epagfolhapagamento p
             WHERE p.nuanomesreferencia = pNuAnoMesReferencia
               AND p.cdtipocalculo = 1
               AND p.cdtipofolhapagamento = pCdTipoFolhaPagamento
               AND p.flcalculodefinitivo = 'S')
      AND c.cdvinculo NOT IN (SELECT v.cdvinculo FROM ecadhistdadosbancariosvinculo v)
      AND (c.vlproventos <> 0 OR c.vlproventos IS NULL);
  end if;
  return vCnt;

exception
when others then
  return -1;
end;

---------------------------------------------------------------------------------------------------------
function pEmpVerLiquidoDaCapa (
  pCdOrgao ecadorgao.cdorgao%type,
  pNuAnoMesReferencia epagfolhapagamento.nuanomesreferencia%type,
  pCdTipoFolhaPagamento epagfolhapagamento.cdtipofolhapagamento%type,
  pCdTipoCalculo epagfolhapagamento.cdtipocalculo%type,
  pNuSequencialFolha epagfolhapagamento.nusequencialfolha%type,
  pFlAtivo epagcapahistrubricavinculo.flativo%type,
  Resultado out Types.ref_cursor) return pls_integer
is
  vCnt pls_integer;
begin
  -- se alterar esta query, alterar a do cursor tambem
  select count(*)
    into vCnt
    from (SELECT SUM(x.vlproventos), SUM(x.vldescontos), (SUM(x.vlproventos) - SUM(x.vldescontos)) liq
            FROM epagcapahistrubricavinculo x
           WHERE x.cdfolhapagamento =
                 (SELECT p.cdfolhapagamento
                    FROM epagfolhapagamento p
                   WHERE p.cdtipofolhapagamento = pCdTipoFolhaPagamento
                     AND p.cdtipocalculo = pCdTipoCalculo
                     AND p.nusequencialfolha = pNuSequencialFolha
                     AND p.flcalculodefinitivo = 'S'
                     AND p.cdorgao = pCdOrgao
                     AND p.nuanomesreferencia = pNuAnoMesReferencia)
             AND x.flativo = pFlAtivo)
   where liq < 0;

  if vCnt > 0 then
    -- se alterar esta query, alterar a do count tambem
    Open Resultado For
    SELECT SUM(x.vlproventos), SUM(x.vldescontos), (SUM(x.vlproventos) - SUM(x.vldescontos)) liq
      FROM epagcapahistrubricavinculo x
     WHERE x.cdfolhapagamento =
           (SELECT p.cdfolhapagamento
              FROM epagfolhapagamento p
             WHERE p.cdtipofolhapagamento = pCdTipoFolhaPagamento
               AND p.cdtipocalculo = pCdTipoCalculo
               AND p.nusequencialfolha = pNuSequencialFolha
               AND p.flcalculodefinitivo = 'S'
               AND p.cdorgao = pCdOrgao
               AND p.nuanomesreferencia = pNuAnoMesReferencia)
       AND x.flativo = pFlAtivo;
  end if;
  return vCnt;

exception
when others then
  return -1;
end;

---------------------------------------------------------------------------------------------------------
function pEmpVerDescontosCapa_x_CC (
  pCdOrgao ecadorgao.cdorgao%type,
  pNuAnoMesReferencia epagfolhapagamento.nuanomesreferencia%type,
  pCdTipoFolhaPagamento epagfolhapagamento.cdtipofolhapagamento%type,
  pCdAgrupamento ecadagrupamento.cdagrupamento%type default 1,
  Resultado out Types.ref_cursor) return pls_integer
is
  vCnt pls_integer;
begin
  -- se alterar esta query, alterar a do cursor tambem
  SELECT count(*)
    into vCnt
    FROM (SELECT hrv.cdfolhapagamento,
                 hrv.cdvinculo,
                 SUM(hrv.vlpagamento) desc_contracheque
            FROM epaghistoricorubricavinculo hrv
           WHERE hrv.cdfolhapagamento IN
                 (SELECT p.cdfolhapagamento
                    FROM epagfolhapagamento p
                   WHERE p.nuanomesreferencia = pNuAnoMesReferencia
                     AND p.cdorgao = pCdOrgao
                     AND p.cdtipocalculo = 1
                     AND p.cdtipofolhapagamento = pCdTipoFolhaPagamento
                     AND p.flcalculodefinitivo = 'S')
             AND hrv.cdrubricaagrupamento IN
                 (SELECT ra.cdrubricaagrupamento
                    FROM epagrubricaagrupamento ra
                   WHERE ra.cdagrupamento = pCdAgrupamento
                     AND ra.cdrubrica IN
                         (SELECT r.cdrubrica
                            FROM epagrubrica r
                           WHERE r.cdtiporubrica IN (5, 6, 7, 8, 11, 13)))
           GROUP BY hrv.cdfolhapagamento, hrv.cdvinculo) a
    LEFT JOIN (SELECT cp.cdfolhapagamento cdfolhapagamento1,
                      cp.cdvinculo cdvinculo1,
                      cp.vldescontos capa_desconto
                 FROM epagcapahistrubricavinculo cp
                WHERE cp.cdfolhapagamento IN
                      (SELECT p.cdfolhapagamento
                         FROM epagfolhapagamento p
                        WHERE p.cdtipofolhapagamento = pCdTipoFolhaPagamento
                          AND p.cdorgao = pCdOrgao
                          AND p.flcalculodefinitivo = 'S'
                          AND p.cdtipocalculo = 1
                          AND p.nuanomesreferencia = pNuAnoMesReferencia)
                  /*AND cp.flativo = 'S'*/) b
      ON a.cdvinculo = b.cdvinculo1
     AND a.cdfolhapagamento = b.cdfolhapagamento1
   WHERE a.desc_contracheque <> b.capa_desconto OR b.capa_desconto IS NULL;

  if vCnt > 0 then
    -- se alterar esta query, alterar a do count tambem
    Open Resultado For
    SELECT *
      FROM (SELECT hrv.cdfolhapagamento,
                   hrv.cdvinculo,
                   SUM(hrv.vlpagamento) desc_contracheque
              FROM epaghistoricorubricavinculo hrv
             WHERE hrv.cdfolhapagamento IN
                   (SELECT p.cdfolhapagamento
                      FROM epagfolhapagamento p
                     WHERE p.nuanomesreferencia = pNuAnoMesReferencia
                       AND p.cdorgao = pCdOrgao
                       AND p.cdtipocalculo = 1
                       AND p.cdtipofolhapagamento = pCdTipoFolhaPagamento
                       AND p.flcalculodefinitivo = 'S')
               AND hrv.cdrubricaagrupamento IN
                   (SELECT ra.cdrubricaagrupamento
                      FROM epagrubricaagrupamento ra
                     WHERE ra.cdagrupamento = pCdAgrupamento
                       AND ra.cdrubrica IN
                           (SELECT r.cdrubrica
                              FROM epagrubrica r
                             WHERE r.cdtiporubrica IN (5, 6, 7, 8, 11, 13)))
             GROUP BY hrv.cdfolhapagamento, hrv.cdvinculo) a
      LEFT JOIN (SELECT cp.cdfolhapagamento cdfolhapagamento1,
                        cp.cdvinculo cdvinculo1,
                        cp.vldescontos capa_desconto
                   FROM epagcapahistrubricavinculo cp
                  WHERE cp.cdfolhapagamento IN
                        (SELECT p.cdfolhapagamento
                           FROM epagfolhapagamento p
                          WHERE p.cdtipofolhapagamento = pCdTipoFolhaPagamento
                            AND p.cdorgao = pCdOrgao
                            AND p.flcalculodefinitivo = 'S'
                            AND p.cdtipocalculo = 1
                            AND p.nuanomesreferencia = pNuAnoMesReferencia)
                    /*AND cp.flativo = 'S'*/) b
        ON a.cdvinculo = b.cdvinculo1
       AND a.cdfolhapagamento = b.cdfolhapagamento1
     WHERE a.desc_contracheque <> b.capa_desconto OR b.capa_desconto IS NULL;
  end if;
  return vCnt;

exception
when others then
  return -1;
end;

---------------------------------------------------------------------------------------------------------
function pEmpVerProventosCapa_x_CC (
  pCdOrgao ecadorgao.cdorgao%type,
  pNuAnoMesReferencia epagfolhapagamento.nuanomesreferencia%type,
  pCdTipoFolhaPagamento epagfolhapagamento.cdtipofolhapagamento%type,
  pCdAgrupamento ecadagrupamento.cdagrupamento%type default 1,
  Resultado out Types.ref_cursor) return pls_integer
is
  vCnt pls_integer;
begin
  -- se alterar esta query, alterar a do cursor tambem
  SELECT count(*)
    into vCnt
    FROM (SELECT hrv.cdfolhapagamento,
                 hrv.cdvinculo,
                 SUM(hrv.vlpagamento) prov_contracheque
            FROM epaghistoricorubricavinculo hrv
           WHERE hrv.cdfolhapagamento IN
                 (SELECT p.cdfolhapagamento
                    FROM epagfolhapagamento p
                   WHERE p.nuanomesreferencia = pNuAnoMesReferencia
                     AND p.cdorgao = pCdOrgao
                     AND p.cdtipocalculo = 1
                     AND p.cdtipofolhapagamento = pCdTipoFolhaPagamento
                     AND p.flcalculodefinitivo = 'S')
             AND hrv.cdrubricaagrupamento IN
                 (SELECT ra.cdrubricaagrupamento
                    FROM epagrubricaagrupamento ra
                   WHERE ra.cdagrupamento = pCdAgrupamento
                     AND ra.cdrubrica IN
                         (SELECT r.cdrubrica
                            FROM epagrubrica r
                           WHERE r.cdtiporubrica IN (1, 2, 3, 4, 10, 12)))
           GROUP BY hrv.cdfolhapagamento, hrv.cdvinculo) a
    LEFT JOIN (SELECT cp.cdfolhapagamento cdfolhapagamento1,
                      cp.cdvinculo cdvinculo1,
                      cp.vlproventos capa_provento
                 FROM epagcapahistrubricavinculo cp
                WHERE cp.cdfolhapagamento IN
                      (SELECT p.cdfolhapagamento
                         FROM epagfolhapagamento p
                        WHERE p.cdtipofolhapagamento = pCdTipoFolhaPagamento
                          AND p.cdorgao = pCdOrgao
                          AND p.flcalculodefinitivo = 'S'
                          AND p.cdtipocalculo = 1
                          AND p.nuanomesreferencia = pNuAnoMesReferencia)
                   /*AND cp.flativo = 'S'*/) b
      ON a.cdvinculo = b.cdvinculo1
     AND a.cdfolhapagamento = b.cdfolhapagamento1
   WHERE a.prov_contracheque <> b.capa_provento OR b.capa_provento IS NULL;

  if vCnt > 0 then
    -- se alterar esta query, alterar a do count tambem
    Open Resultado For
    SELECT *
      FROM (SELECT hrv.cdfolhapagamento,
                   hrv.cdvinculo,
                   SUM(hrv.vlpagamento) prov_contracheque
              FROM epaghistoricorubricavinculo hrv
             WHERE hrv.cdfolhapagamento IN
                   (SELECT p.cdfolhapagamento
                      FROM epagfolhapagamento p
                     WHERE p.nuanomesreferencia = pNuAnoMesReferencia
                       AND p.cdorgao = pCdOrgao
                       AND p.cdtipocalculo = 1
                       AND p.cdtipofolhapagamento = pCdTipoFolhaPagamento
                       AND p.flcalculodefinitivo = 'S')
               AND hrv.cdrubricaagrupamento IN
                   (SELECT ra.cdrubricaagrupamento
                      FROM epagrubricaagrupamento ra
                     WHERE ra.cdagrupamento = pCdAgrupamento
                       AND ra.cdrubrica IN
                           (SELECT r.cdrubrica
                              FROM epagrubrica r
                             WHERE r.cdtiporubrica IN (1, 2, 3, 4, 10, 12)))
             GROUP BY hrv.cdfolhapagamento, hrv.cdvinculo) a
      LEFT JOIN (SELECT cp.cdfolhapagamento cdfolhapagamento1,
                        cp.cdvinculo cdvinculo1,
                        cp.vlproventos capa_provento
                   FROM epagcapahistrubricavinculo cp
                  WHERE cp.cdfolhapagamento IN
                        (SELECT p.cdfolhapagamento
                           FROM epagfolhapagamento p
                          WHERE p.cdtipofolhapagamento = pCdTipoFolhaPagamento
                            AND p.cdorgao = pCdOrgao
                            AND p.flcalculodefinitivo = 'S'
                            AND p.cdtipocalculo = 1
                            AND p.nuanomesreferencia = pNuAnoMesReferencia)
                     /*AND cp.flativo = 'S'*/) b
        ON a.cdvinculo = b.cdvinculo1
       AND a.cdfolhapagamento = b.cdfolhapagamento1
     WHERE a.prov_contracheque <> b.capa_provento OR b.capa_provento IS NULL;
  end if;
  return vCnt;

exception
when others then
  return -1;
end;

---------------------------------------------------------------------------------------------------------
procedure pEmpVerTudo (pNuAnoMesReferencia epagfolhapagamento.nuanomesreferencia%type) is

  -- executa todas as consultas da documentacao para todas as folhas fechadas
  --   Procedimentos para solucionar problemas na geracao dos arquivos de empenho
  --     https://docs.google.com/document/d/1UWQ8Cz5PzB3aOzN6IKvEhlBhyNhSyHLjA9HjR4AJq40/edit
  -- guarda o resultado na tabela ePagAnalisePosFolha

  vCnt pls_integer;
  vResultado Types.ref_cursor;

  vNuAnoRef integer;
  vNuMesRef integer;
  vNuAnoMesReferencia epagfolhapagamento.nuanomesreferencia%type;
  vCdOrgaoAnt integer;
  vCdTipoCalculoAnt integer;
  vCdTipoFolhaPagamentoAnt integer;
  vNuSequencialFolhaAnt integer;

  procedure pInsereRegistroAnalise (
    pDeAssunto in varchar2,
    pQtProblemas in integer,
    pNuAnoMesReferencia epagfolhapagamento.nuanomesreferencia%type,
    pCdAgrupamento ecadagrupamento.cdagrupamento%type,
    pCdOrgao ecadorgao.cdorgao%type,
    pCdTipoFolhaPagamento epagfolhapagamento.cdtipofolhapagamento%type default null,
    pCdTipoCalculo epagfolhapagamento.cdtipocalculo%type default null,
    pNuSequencialFolha epagfolhapagamento.nusequencialfolha%type default null,
    pCdFolhaPagamento epagfolhapagamento.cdfolhapagamento%type default null,
    pCdCreditoBancario in epaghistoricoempenhorubrica.cdcreditobancario%type default null,
    pFlAtivo epagcapahistrubricavinculo.flativo%type default null) is
  begin
    if pQtProblemas != 0 or pCdAgrupamento = 0 then
    --if true then
      insert into epaganaliseposfolha values (
             sPagAnalisePosFolha.nextval
           , sysdate
           , pDeAssunto
           , pQtProblemas
           , pNuAnoMesReferencia
           , pCdAgrupamento
           , pCdOrgao
           , pCdTipoFolhaPagamento
           , pCdTipoCalculo
           , pNuSequencialFolha
           , pCdFolhaPagamento
           , pCdCreditoBancario
           , pFlAtivo
           , null, null);
    end if;
  end pInsereRegistroAnalise;

begin

  vNuAnoMesReferencia := nvl(pNuAnoMesReferencia, to_number(to_char(sysdate, 'yyyymm')));

  pInsereRegistroAnalise('inicio', null, vNuAnoMesReferencia, 0, 0);
  commit;

  vNuAnoRef := vNuAnoMesReferencia / 100;
  vNuMesRef := vNuAnoMesReferencia - vNuAnoRef * 100;

  vCdOrgaoAnt := 0;
  vCdTipoFolhaPagamentoAnt := 0;
  vCdTipoCalculoAnt := 0;
  vNuSequencialFolhaAnt := 0;
  for rec in (
    select fp.cdfolhapagamento, fp.cdagrupamento, fp.cdorgao, fp.cdtipofolhapagamento, fp.cdtipocalculo, fp.nusequencialfolha
      from epagfolhapagamento fp
     where fp.nuanomesreferencia = vNuAnoMesReferencia
       and fp.flfolhafechada = 'S'
       and fp.cdagrupamento in (1, 134)
     order by fp.cdagrupamento, fp.cdorgao, fp.cdtipofolhapagamento, fp.cdtipocalculo, fp.nusequencialfolha
  ) loop

    vCnt := pEmpVerLiquidNegativoCapaCC(rec.cdfolhapagamento, vResultado);
    pInsereRegistroAnalise('pEmpVerLiquidNegativoCapaCC', vCnt, vNuAnoMesReferencia, rec.cdagrupamento, rec.cdorgao,
                           null, null, null, rec.cdfolhapagamento);

    if rec.cdorgao != vCdOrgaoAnt or rec.cdtipofolhapagamento != vCdTipoFolhaPagamentoAnt
       or rec.cdtipocalculo != vCdTipoCalculoAnt or rec.nusequencialfolha != vNuSequencialFolhaAnt
    then
      vCnt := pEmpRubricaSemElementoDespesa(rec.cdorgao, vNuMesRef, vNuAnoRef, rec.cdtipofolhapagamento,
                                            rec.cdtipocalculo, rec.nusequencialfolha, vResultado);
      pInsereRegistroAnalise('pEmpRubricaSemElementoDespesa', vCnt, vNuAnoMesReferencia, rec.cdagrupamento, rec.cdorgao,
                             rec.cdtipofolhapagamento, rec.cdtipocalculo, rec.nusequencialfolha);

      vCnt := pEmpVerLiquidoDaCapa(rec.cdorgao, vNuAnoMesReferencia, rec.cdtipofolhapagamento,
                                   rec.cdtipocalculo, rec.nusequencialfolha, 'S', vResultado);
      pInsereRegistroAnalise('pEmpVerLiquidoDaCapa', vCnt, vNuAnoMesReferencia, rec.cdagrupamento,
                             rec.cdorgao, rec.cdtipofolhapagamento, rec.cdtipocalculo, rec.nusequencialfolha, null, null, 'S');
      vCnt := pEmpVerLiquidoDaCapa(rec.cdorgao, vNuAnoMesReferencia, rec.cdtipofolhapagamento,
                                   rec.cdtipocalculo, rec.nusequencialfolha, 'N', vResultado);
      pInsereRegistroAnalise('pEmpVerLiquidoDaCapa', vCnt, vNuAnoMesReferencia, rec.cdagrupamento,
                             rec.cdorgao, rec.cdtipofolhapagamento, rec.cdtipocalculo, rec.nusequencialfolha, null, null, 'N');
    end if;

    if rec.cdtipofolhapagamento != vCdTipoFolhaPagamentoAnt then
      vCnt := pEmpExisteRubLiquidoNegativo(vNuAnoMesReferencia, rec.cdtipofolhapagamento, vResultado);
      pInsereRegistroAnalise('pEmpExisteLiquidoNegativo', vCnt, vNuAnoMesReferencia, rec.cdagrupamento,
                             rec.cdorgao, rec.cdtipofolhapagamento);

      vCnt := pEmpVerDadosBancarDuplicados(vNuAnoMesReferencia, rec.cdtipofolhapagamento, vResultado);
      pInsereRegistroAnalise('pEmpVerDadosBancarDuplicados', vCnt, vNuAnoMesReferencia, rec.cdagrupamento,
                             rec.cdorgao, rec.cdtipofolhapagamento);

      vCnt := pEmpVerVinculosSemDadosBancar(vNuAnoMesReferencia, rec.cdtipofolhapagamento, vResultado);
      pInsereRegistroAnalise('pEmpVerVinculosSemDadosBancar', vCnt, vNuAnoMesReferencia, rec.cdagrupamento,
                             rec.cdorgao, rec.cdtipofolhapagamento);

    end if;

    if rec.cdorgao != vCdOrgaoAnt or rec.cdtipofolhapagamento != vCdTipoFolhaPagamentoAnt then
      vCnt := pEmpVerLiquidNegativoFolNormal(vNuAnoMesReferencia, rec.cdorgao, rec.cdtipofolhapagamento,
                                             rec.cdagrupamento, vResultado);
      pInsereRegistroAnalise('pEmpVerLiquidNegativoFolNormal', vCnt, vNuAnoMesReferencia, rec.cdagrupamento,
                             rec.cdorgao, rec.cdtipofolhapagamento);

      vCnt := pEmpVerLiquidNegativoPenAlimen(vNuAnoMesReferencia, rec.cdorgao, rec.cdtipofolhapagamento,
                                             rec.cdagrupamento, vResultado);
      pInsereRegistroAnalise('pEmpVerLiquidNegativoPenAlimen', vCnt, vNuAnoMesReferencia, rec.cdagrupamento,
                             rec.cdorgao, rec.cdtipofolhapagamento);

      vCnt := pEmpVerDescontosCapa_x_CC(rec.cdorgao, vNuAnoMesReferencia, rec.cdtipofolhapagamento, rec.cdagrupamento, vResultado);
      pInsereRegistroAnalise('pEmpVerDescontosCapa_x_CC', vCnt, vNuAnoMesReferencia, rec.cdagrupamento,
                             rec.cdorgao, rec.cdtipofolhapagamento);

      vCnt := pEmpVerProventosCapa_x_CC(rec.cdorgao, vNuAnoMesReferencia, rec.cdtipofolhapagamento, rec.cdagrupamento, vResultado);
      pInsereRegistroAnalise('pEmpVerProventosCapa_x_CC', vCnt, vNuAnoMesReferencia, rec.cdagrupamento,
                             rec.cdorgao, rec.cdtipofolhapagamento);
    end if;

    if rec.cdorgao != vCdOrgaoAnt or rec.cdtipofolhapagamento != vCdTipoFolhaPagamentoAnt
       or rec.cdtipocalculo != vCdTipoCalculoAnt
    then
      for rCB in (
        select cb.cdcreditobancario
          from epagcreditobancario cb
         where cb.cdorgao = rec.cdorgao
           and cb.nuano = vNuAnoRef
           and cb.numes = vNuMesRef
           and cb.cdtipofolhapagamento = rec.cdtipofolhapagamento
           and cb.cdtipocalculo = rec.cdtipocalculo
           and cb.nufolha = rec.nusequencialfolha
      ) loop
        vCnt := pEmpServsPensaoNaoEstaoRelCred(rCB.cdcreditobancario, vNuAnoMesReferencia, rec.cdorgao,
                                               rec.cdtipofolhapagamento, rec.cdtipocalculo, vResultado);
        pInsereRegistroAnalise('pEmpServsPensaoNaoEstaoRelCred', vCnt, vNuAnoMesReferencia, rec.cdagrupamento,
                               rec.cdorgao, rec.cdtipofolhapagamento, rec.cdtipocalculo,
                               null, null, rCB.cdcreditobancario);
      end loop;
    end if;

    vCdOrgaoAnt := rec.cdorgao;
    vCdTipoFolhaPagamentoAnt := rec.cdtipofolhapagamento;
    vCdTipoCalculoAnt := rec.cdtipocalculo;
    vNuSequencialFolhaAnt := rec.nusequencialfolha;

    commit;

  end loop;

  pInsereRegistroAnalise('fim', null, vNuAnoMesReferencia, 0, 0);
  commit;

exception
when others then
  pInsereRegistroAnalise(sqlerrm, null, vNuAnoMesReferencia, 0, 0);
  commit;

end;

---------------------------------------------------------------------------------------------------------
procedure pEmpVerTudoViaJob (pNuAnoMesReferencia epagfolhapagamento.nuanomesreferencia%type) is
  i integer;
  vNuAnoMesReferencia epagfolhapagamento.nuanomesreferencia%type;
begin
  vNuAnoMesReferencia := nvl(pNuAnoMesReferencia, to_number(to_char(sysdate, 'yyyymm')));
  -- inicializa o job imediatamente
  DBMS_JOB.SUBMIT(i, 'sigrh.XTMPAG_util.pempvertudo('|| to_char(vNuAnoMesReferencia) ||');', sysdate, null);
  commit;
end;

---------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------

end XTMPAG_UTIL;
/
