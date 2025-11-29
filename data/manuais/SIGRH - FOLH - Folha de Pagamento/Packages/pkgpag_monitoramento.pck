CREATE OR REPLACE PACKAGE pkgpag_monitoramento IS

  -- Author  : ANDREYMB
  -- Created : 10/08/2015 16:47:29
  -- Purpose : Pacote de monitoramento dos jobs de calculo da folha

  FUNCTION qtd_calculos_atrasados RETURN NUMBER;

  FUNCTION qtd_calculos_em_andamento RETURN NUMBER;

  function qtd_baixa_pessoas_calculadas return pls_integer;

  FUNCTION qtd_erros RETURN NUMBER;

  FUNCTION qtd_erros_criticos RETURN NUMBER;

  FUNCTION qtd_pessoas_calculadas RETURN NUMBER;

  FUNCTION qtd_calc_interrompidos RETURN NUMBER;

  FUNCTION qtd_calc_andamento RETURN NUMBER;

  FUNCTION progresso_calc RETURN NUMBER;

  FUNCTION str_calculos_em_andamento RETURN VARCHAR2;

  FUNCTION ver_ref_circular_rubrica RETURN pls_integer;

  procedure p_atualiza_monit_pacote_valido;

  procedure p_compila_pacote_invalido;

  FUNCTION ver_pacote_invalido RETURN VARCHAR2;

  procedure p_insere_reg_monitoramento (pTipo in varchar2, pParametro in varchar2
                                      , pChave in varchar2, pValor in varchar2
                                      , pQuantidade in number default null
                                      , pObservacao in varchar2 default null);

  function ver_sigrh_bloqueado return integer;

  procedure p_tentativa_login_frustrada;

  procedure p_ver_tentativa_login_frustrada (p_dt_ini in varchar2);

  FUNCTION ver_base_hom_atualizada_fds RETURN pls_integer;

END pkgpag_monitoramento;
/
CREATE OR REPLACE PACKAGE BODY pkgpag_monitoramento IS

-- Retorna a quantidade de calculos de folha que estao
-- atrasados, ou seja, foram agendados mas nao
-- foram iniciados ate o momento
FUNCTION qtd_calculos_atrasados RETURN NUMBER IS
  qtd_calculos_atrasados NUMBER;
BEGIN

  SELECT COUNT(hpc.cdhistoricoparamcalculo)
    INTO qtd_calculos_atrasados
    FROM epaghistoricoparamcalculo hpc
   WHERE hpc.dtprocessamento+
         --margem de 5 min + hpc.qtpessoas * 0.0001
         (TRUNC(hpc.qtpessoas * 0.0002, 0) + 5)/24/60/1 < SYSDATE
     AND hpc.instatus = 4
     AND hpc.cdagrupamento IN (1,134);

  RETURN qtd_calculos_atrasados;

  EXCEPTION
    WHEN OTHERS THEN

    SELECT COUNT(hpc.cdhistoricoparamcalculo)
      INTO qtd_calculos_atrasados
      FROM epaghistoricoparamcalculo hpc
     WHERE hpc.dtprocessamento+ 5/24/60/1 < SYSDATE  --margem de 5 min
       AND hpc.instatus = 4
       AND hpc.cdagrupamento IN (1,134);

     RETURN qtd_calculos_atrasados;
END;

-- Retorna a quantidade de calculos de folha em andamento
FUNCTION qtd_calculos_em_andamento RETURN NUMBER IS
  qtd_calculos_em_andamento NUMBER;
  qtd_pessoas               NUMBER;
BEGIN
  SELECT COUNT(hpc.cdhistoricoparamcalculo), nvl(SUM(hpc.qtpessoas), 0)
    INTO qtd_calculos_em_andamento, qtd_pessoas
    FROM epaghistoricoparamcalculo hpc
   WHERE hpc.instatus in (1,9)-- EM ANDAMENTO E CALC DO DUPLO VINCULO
     AND hpc.cdagrupamento IN (1,134);

  -- SÓ MONITORA CALCULOS ACIMA DE 5000 PESSOAS
  IF NVL(qtd_calculos_em_andamento,0) > 0 AND NVL(qtd_pessoas,0) > 5000
    THEN
    RETURN qtd_calculos_em_andamento;
  ELSE
    RETURN 0;
  END IF;
END;

function qtd_baixa_pessoas_calculadas
  return pls_integer -- 1: sim; 0: nao
is
  vExcluirReg boolean;
  vQtdeBaixa pls_integer;
begin
--return 0;
  vQtdeBaixa := 0;
  for rec in (
    select to_number(m.valor) cdhistoricoparamcalculo, m.quantidade, m.rowid m_rowid
      from eadmmonitoramento m
     where m.tipo = 'MPFP'
       and m.parametro = 'BQPC'
       and m.chave = 'CDHISTORICOPARAMCALCULO'
  ) loop
    vExcluirReg := false;
    if rec.quantidade > 0 then
      begin
        select hpc.cdhistoricoparamcalculo
          into rec.cdhistoricoparamcalculo
          from epaghistoricoparamcalculo hpc, eadmtarefa t
         where t.cdtarefa = hpc.cdtarefa
           and hpc.cdhistoricoparamcalculo = rec.cdhistoricoparamcalculo
           and (t.cdsituacaotarefa = 2 or t.dtterminoreal is null
               or hpc.instatus in (1, 9))
           and hpc.cdagrupamento in (1, 134);
      exception
      when no_data_found then
        vExcluirReg := true;
      end;
    else
      vExcluirReg := true;
    end if;
    if vExcluirReg then
      delete eadmmonitoramento m
       where rowid = rec.m_rowid;
    else
      vQtdeBaixa := 1;
    end if;
  end loop;
  commit;
  return vQtdeBaixa;
end;

-- Retorna a quantidade de erros/excecoes ocorridos
-- durante os calculos em andamento
FUNCTION qtd_erros RETURN NUMBER IS
  qtd_erros NUMBER;
BEGIN
  SELECT COUNT(lpc.cdlogprocessamento)
    INTO qtd_erros
    FROM epaghistoricoparamcalculo hpc
   INNER JOIN epaglogprocessamento lpc
      ON lpc.cdhistoricoparamcalculo = hpc.cdhistoricoparamcalculo
         AND lpc.cdtipoocorrencia = 1
         AND lpc.delog NOT LIKE '%ORA-%'
   WHERE hpc.instatus = 1
     AND hpc.cdagrupamento IN (1,134); -- EM ANDAMENTO

  RETURN qtd_erros;
END;

-- Retorna a quantidade de erros CRITICOS ocorridos
-- durante os calculos em andamento
FUNCTION qtd_erros_criticos RETURN NUMBER IS
  qtd_erros_criticos NUMBER;
BEGIN
  SELECT COUNT(lpc.cdlogprocessamento)
    INTO qtd_erros_criticos
    FROM epaghistoricoparamcalculo hpc
   INNER JOIN epaglogprocessamento lpc
      ON lpc.cdhistoricoparamcalculo = hpc.cdhistoricoparamcalculo
         AND lpc.cdtipoocorrencia = 1
         AND lpc.delog LIKE '%ORA-%'
   WHERE hpc.instatus = 1; -- EM ANDAMENTO

  RETURN qtd_erros_criticos;
END;

-- Retorna a quantidade de pessoas ja tiveram folha
-- calculada pelos calculos de folha em andamento
FUNCTION qtd_pessoas_calculadas RETURN NUMBER IS
  qtd_pessoas_calculadas NUMBER;
  --vinstatus              INTEGER;
  --vCdtarefa              INTEGER;
  qtd_calc_andamento     INTEGER;

BEGIN

  SELECT COUNT(hpc.cdtarefa)
    INTO qtd_calc_andamento
    FROM epaghistoricoparamcalculo hpc
   INNER JOIN EADMTAREFA T
      ON T.CDTAREFA = HPC.CDTAREFA
   WHERE hpc.instatus = 1
     AND hpc.cdagrupamento IN (1, 134)
     AND T.CDSITUACAOTAREFA = 2;

  IF qtd_calc_andamento > 1 THEN
    SELECT nvl(SUM(hpc.qtpessoascalculadas), 0)
      INTO qtd_pessoas_calculadas
      FROM epaghistoricoparamcalculo hpc
     WHERE hpc.cdtarefa in
           (SELECT hp.cdtarefa
              FROM epaghistoricoparamcalculo hp
             INNER JOIN EADMTAREFA T
                ON T.CDTAREFA = HP.CDTAREFA
               AND T.CDSITUACAOTAREFA = 2
             WHERE hp.instatus in (1, 9)
               AND hp.cdagrupamento IN (1, 134));

  ELSE
    RETURN NULL;
  END IF;

  RETURN qtd_pessoas_calculadas;

EXCEPTION
  WHEN OTHERS THEN
    RETURN NULL;
END;

-- RETORNA A QUANTIDADE DE CALCULOS DE FOLHA
-- INTERROMPIDOS
FUNCTION qtd_calc_interrompidos RETURN NUMBER IS
  qtd_calculos_interrompidos NUMBER;
BEGIN
  SELECT COUNT(hpc.cdhistoricoparamcalculo)
    INTO qtd_calculos_interrompidos
    FROM epaghistoricoparamcalculo hpc
   INNER JOIN epaghistoricoparamcalculoorgao o
      ON o.cdhistoricoparamcalculo = hpc.cdhistoricoparamcalculo
   WHERE hpc.instatus = 3 -- INTERROMPIDO
     and trunc(hpc.dtprocessamento) >= trunc(sysdate)-1 -- nao precisa dessa verificacao para processamentos antigos.
      -- REGRA PARA EVITAR QUE CALCULOS PRE-AGENDADOS E INTERROMPIDOS POSSAM GERAR ERRO (TESTES)
     AND (o.dtinicio IS NULL OR o.dtinicio >= hpc.dtprocessamento)
     AND hpc.cdagrupamento IN (1,134) ;

  RETURN qtd_calculos_interrompidos;
END;

FUNCTION qtd_calc_andamento RETURN NUMBER IS
  qtd_calc_andamento NUMBER;
BEGIN

  SELECT COUNT(hpc.cdtarefa)
    INTO qtd_calc_andamento
    FROM epaghistoricoparamcalculo hpc
   INNER JOIN EADMTAREFA T
      ON T.CDTAREFA = HPC.CDTAREFA
   WHERE hpc.instatus = 1
     AND hpc.cdagrupamento IN (1, 134)
     AND T.CDSITUACAOTAREFA = 2;-- EM ANDAMENTO

   RETURN qtd_calc_andamento;
END;

FUNCTION progresso_calc RETURN NUMBER IS
  progresso_calc NUMBER;
  vcdtarefa      INTEGER;

BEGIN

  --seleciona o 1 calculo que comecou
  SELECT cdtarefa
    INTO vcdtarefa
    FROM (SELECT tar.cdtarefa
            FROM eadmtarefa tar
           INNER JOIN epaghistoricoparamcalculo hc
              ON tar.cdtarefa = hc.cdtarefa
           WHERE hc.instatus = 2 -- em andamento
          -- AND hc.cdagrupamento = 1
           ORDER BY tar.dtinicioreal ASC)
   WHERE rownum < 2;

  SELECT CASE
           WHEN hpc.qtpessoascalculadas =
                trunc(hpc.qtpessoascalculadas / greatest(hpc.qtpessoas, 1),
                      4) THEN
            0
           ELSE
            hpc.qtpessoascalculadas / hpc.qtpessoas
         END
    INTO progresso_calc
    FROM epaghistoricoparamcalculo hpc
   WHERE hpc.cdtarefa = vcdtarefa;

  RETURN progresso_calc;

END;

FUNCTION str_calculos_em_andamento RETURN VARCHAR2 IS
  pstr_calculos_em_andamento VARCHAR2(15);
BEGIN

WITH calculo AS
 (SELECT MAX(cdhistoricoparamcalculo) cdhistoricoparamcalculo FROM epaghistoricoparamcalculo
 WHERE instatus in (1,9) AND cdagrupamento IN (1,134)) -- EM ANDAMENTO

SELECT a.sgagrupamento
INTO pstr_calculos_em_andamento
  FROM calculo c
 INNER JOIN epaghistoricoparamcalculo hpc
    ON hpc.cdhistoricoparamcalculo = c.cdhistoricoparamcalculo
 INNER JOIN ecadagrupamento a
    ON a.cdagrupamento = hpc.cdagrupamento;

  RETURN pstr_calculos_em_andamento;

  EXCEPTION
    WHEN OTHERS THEN
      RETURN 'Nenhum calculo';

END;

FUNCTION ver_ref_circular_rubrica RETURN pls_integer IS
BEGIN
  if pkgpag_tar.FExisteReferenciaCircularRub then
    return 1;
  else
    return 0;
  end if;
END;

procedure p_atualiza_monit_pacote_valido is
begin
  for rec in (
    select o.OBJECT_NAME
      from eadmmonitoramento m, all_objects o
     where o.OBJECT_NAME = m.valor
       and o.OWNER = 'SIGRH'
       and o.object_type in (/*'PACKAGE', */'PACKAGE BODY')
       and m.tipo = 'MPI'
       and m.parametro = 'TCP'
       and m.quantidade >= 2
       and o.status = 'VALID'
     order by o.OBJECT_NAME
  ) loop
    update eadmmonitoramento u set
           u.quantidade = 0
         , u.observacao = null
         , u.horario = sysdate
     where u.tipo = 'MPI'
       and u.parametro = 'TCP'
       and u.valor = rec.object_name;
    commit;
  end loop;
end;

procedure p_compila_pacote_invalido is

  vMTP varchar2(30) := 'MPI';
  vMPA varchar2(30) := 'TCP';
  vQtd number;
  vObs varchar2(500);

begin

  for rec in (
    select distinct o.OBJECT_NAME, o.status
      from all_objects o
     where o.OWNER = 'SIGRH'
       --AND STATUS = 'INVALID'
       and o.object_type in (/*'PACKAGE', */'PACKAGE BODY')
       and o.OBJECT_NAME not in ('PKGMANAD', 'PKG_DML_LOG', 'XTMPAG_GERAL')
     order by o.OBJECT_NAME
  ) loop

    if rec.status != 'VALID' then

      begin
        select m.quantidade
          into vQtd
          from eadmmonitoramento m
         where m.tipo = vMTP
           and m.parametro = vMPA
           and m.valor = rec.object_name;
      exception
      when no_data_found then
        insert into eadmmonitoramento (tipo, parametro, valor, quantidade)
            values (vMTP, vMPA, rec.object_name, 0);
        vQtd := 0;
      when others then
        delete eadmmonitoramento d
         where d.tipo = vMTP and d.parametro = vMPA and d.valor = rec.object_name
           and rownum != 1;
        vQtd := 0;
      end;

      if vQtd between 0 and 2 - 1 then -- parametrizar o 2 (qtde de tentativas)
        vQtd := vQtd + 1;
        vObs := null;
        begin
          execute immediate 'alter package sigrh.'|| rec.object_name ||' compile';
        exception
        when others then
          vObs := sqlerrm;
        end;
        update eadmmonitoramento u set
               u.quantidade = vQtd
             , u.observacao = vObs
             , u.horario = sysdate
         where u.tipo = vMTP and u.parametro = vMPA and u.valor = rec.object_name;
      end if;

    else
      update eadmmonitoramento u set
             u.quantidade = 0
           , u.observacao = null
           , u.horario = sysdate
       where u.tipo = vMTP and u.parametro = vMPA and u.valor = rec.object_name;
    end if;

    commit;

  end loop;

end;

FUNCTION ver_pacote_invalido RETURN VARCHAR2 IS
  pstr_pacote_invalido VARCHAR2(2000);
BEGIN
  /* DICA: pra ignorar um pacote, alterar a quantidade pra -1 em eadmmonitoramento */
  select nvl(LISTAGG(o.OBJECT_NAME, ', ') WITHIN GROUP (ORDER BY o.OBJECT_NAME), 'OK')
    into pstr_pacote_invalido
    from all_objects o
   where o.OWNER = 'SIGRH'
     AND o.STATUS = 'INVALID'
     and o.object_type in (/*'PACKAGE', */'PACKAGE BODY')
     and exists (select 1
                   from eadmmonitoramento m
                  where m.tipo = 'MPI'
                    and m.parametro = 'TCP'
                    and m.valor = o.OBJECT_NAME
                    and m.quantidade >= 2)
     and o.OBJECT_NAME not in ('PKGMANAD', 'PKG_DML_LOG', 'XTMPAG_GERAL'); -- invalidos mas que nunca precisarao de monitoramento
  return pstr_pacote_invalido;
exception
when others then
  return 'OK';
END;

procedure p_insere_reg_monitoramento (pTipo in varchar2, pParametro in varchar2
                                    , pChave in varchar2, pValor in varchar2
                                    , pQuantidade in number default null
                                    , pObservacao in varchar2 default null)
is
  PRAGMA AUTONOMOUS_TRANSACTION;
begin
  insert into eadmmonitoramento
    values (pTipo, pParametro, pChave, pValor, pQuantidade, sysdate, pObservacao);
  commit;
end;

procedure p_tentativa_login_frustrada is
  vLocation varchar2(50);
  vFileName varchar2(50);
  vLine varchar2(200);
  vDtUltimaOcorrencia varchar2(14);
  vFile utl_file.file_type;
begin

  vLocation := 'SCRIPTS_ZABBIX';
  vFileName := 'tentativa_login_frustrada.dat';
  --utl_file.fremove(vLocation, vFileName);

  begin
    vFile := utl_file.fopen(vLocation, vFileName, 'r');
    utl_file.get_line(vFile, vLine);
    vDtUltimaOcorrencia := substr(vLine, 1, 16);
    dbms_output.put_line(vLine);
  exception
  when others then
    vFile := utl_file.fopen(vLocation, vFileName, 'a');
    vDtUltimaOcorrencia := null;
  end;
  utl_file.fclose(vFile);

  if vDtUltimaOcorrencia is null then
    vDtUltimaOcorrencia := to_char(systimestamp - interval '31' minute, 'yyyymmddhh24miss');
  end if;

  select to_char(ts, 'yyyymmddhh24miss')
    into vDtUltimaOcorrencia
    from (select max(at.TIMESTAMP) ts
            from user_audit_trail at
           where at.returncode = 1017
             and at.USERNAME = 'SIGRH'
             and at.TIMESTAMP > to_timestamp(vDtUltimaOcorrencia, 'yyyymmddhh24miss'));

  vFile := utl_file.fopen(vLocation, vFileName, 'w');
  utl_file.put_line(vFile, vDtUltimaOcorrencia);
  utl_file.fclose(vFile);

end;

procedure p_ver_tentativa_login_frustrada (p_dt_ini in varchar2) is
begin

  -- ultima verificacao: 20240801 (data do bloqueio)

  for rec in (
    select at.OS_USERNAME, at.DBUSERNAME, at.USERHOST, at.EVENT_TIMESTAMP
      from UNIFIED_AUDIT_TRAIL at
     where at.return_code = 1017
       and at.DBUSERNAME = 'SIGRH'
--and rownum = 1
       and at.EVENT_TIMESTAMP > to_timestamp(p_dt_ini ||'000000', 'yyyymmddhh24miss')
  ) loop
    dbms_output.put_line(rec.os_username);
    dbms_output.put_line(rec.DBUSERNAME);
    dbms_output.put_line(rec.userhost);
    dbms_output.put_line(to_char(rec.EVENT_TIMESTAMP));
    dbms_output.put_line('');
  end loop;

end;

function ver_sigrh_bloqueado return integer is
  vCnt integer;
begin

  select count(*)
    into vCnt
    from user_users u
   where u.username = 'SIGRH'
     and u.account_status != 'OPEN';

  return vCnt;

end;

FUNCTION ver_base_hom_atualizada_fds RETURN pls_integer IS
  -- fds: final de semana
  -- Essa function foi desenvolvida para monitoramento via zabbix, uma verificacao no inicio da semana,
  --   mas pode ser executada em qualquer dia util pra ver se a base foi duplicada no fds anterior.
  vDtUltDomingo date;
  vAux pls_integer;
BEGIN

  vDtUltDomingo := null;
  vAux := 0;
  loop
    if to_char(sysdate - vAux, 'D') = '1' then
      vDtUltDomingo := trunc(sysdate - vAux);
      exit;
    else
      vAux := vAux + 1;
    end if;
  end loop;

  -- foi incluido no final do script de duplicate um update no orgao SEA
  select count(*)
    into vAux
    from ecadorgao o
   where o.cdorgao = 29
     and trunc(o.dtultalteracao) in (vDtUltDomingo, trunc(vDtUltDomingo - 1));

  return vAux;
END;



END pkgpag_monitoramento;
/
