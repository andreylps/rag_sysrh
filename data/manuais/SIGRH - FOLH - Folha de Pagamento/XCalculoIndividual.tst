PL/SQL Developer Test script 3.0
296

-- 677955 folha 785
declare
  pcalculoretorno  pkgpag_cal.rcalculoretorno;  
  pxcalculoretorno xtmpag_cal.rcalculoretorno;  
  vTabParam        PKGSOCConst.tVarchar2;
  vCdVinculo       INTEGER;
  pCdFolhaPagamento integer;
  pDtCalculo DATE;
  pCdOrgao integer;
  vFlCalculodefinitivo CHAR(1);
  pCdTipoFolhaPagamento integer;
  vdthcalc   DATE;
   
  PROCEDURE PContinua  (pCalculoRetorno  OUT PKGPAG_CAL.rCalculoRetorno, pFlCalculoDefinitivo IN CHAR, pDtCalculo IN DATE) IS
     vCalculo             PKGPAG_CAL.rCalculo;
     pLog                 BOOLEAN := TRUE;
     pTrace               BOOLEAN := TRUE;
     pVlDiferencaValor    NUMBER := 0;
     pFlPagaAdiantamento  CHAR   := 'N';
  BEGIN
    
     vCalculo.FlGeral                 := 'I';
     vCalculo.CdTarefa                := NULL;
     vCalculo.CdHistoricoParamCalculo := 0;
     vCalculo.InTipoExecucao          := 2; -- 2 - Processar a folha 
     vCalculo.CdCalculo               := :pCdCalculoContinua;
     vCalculo.CdCalculoPai            := vCalculo.CdCalculo;

     PKGPAG_VAR.vgCalculo             := vCalculo;

     IF NOT :pCdTipoFolhaPagamento IN ( PKGPAG_TIPO.cnTpFolha13
                                      , PKGPAG_TIPO.cnTpFolhaAdiant13
                                      , PKGPAG_TIPO.cnTpFolhaResidente13
                                      , PKGPAG_TIPO.cnTpFolhaFunebre13
                                      , pkgpag_tipo.cnTpFolhaCtisp13
                                      , pkgpag_tipo.cnTpFolhaAdiant13Ctisp
                                      , pkgpag_tipo.cnTpFolhaProdex13
                                      , pkgpag_tipo.cnTpFolhaHonorarios13
                                      , pkgpag_tipo.cnTpFolhaHonorarProcuradores13) then

         -- Folha Normal

        PKGPAG_CAL.PProcessarCalculoNormal    (pCalculo                   => vCalculo,
                                               pDtCalculo                 => pDtCalculo,
                                               pFlDefinitivo              => pFlCalculoDefinitivo,
                                               pFlPagaAdiantamento13sal   => pFlPagaAdiantamento,
                                               pVlDiferencaValor          => pVlDiferencaValor,
                                               pLog                       => pLog,
                                               pTrace                     => pTrace,
                                               pCalculoRetorno            => pCalculoRetorno);

     ELSE

        PKGPAG_DT.PProcessarCalculo13Salario (pCalculo                   => vCalculo,
                                              pDtCalculo                 => pDtCalculo,
                                              pFlDefinitivo              => pFlCalculoDefinitivo,
                                              pLog                       => pLog,
                                              pTrace                     => pTrace,
                                              pCalculoRetorno            => pCalculoRetorno);

 
     END IF;
  
  END;
   
  PROCEDURE PCalcula (pCdVinculo IN INTEGER) IS
    
  BEGIN
     
  dbms_output.put_line ('Iniciando calculo...');
    
  vdthcalc := SYSDATE;
  
  IF :pFlCalculoAntigo = 0 THEN

     IF :pCdCalculoContinua in (0, 1 ) THEN
       
        pkgpag_tar.PProcessarCalculoIndividual(pcdfolhapagamento => pcdfolhapagamento,
                                               pcdvinculo => pcdvinculo,
                                               pdtcalculo => pdtcalculo,                                    
                                               pflcalculodefinitivo => vflcalculodefinitivo,
                                               pCdCalculoContinua => :pCdCalculoContinua,
                                               pcalculoretorno => pcalculoretorno);
     
        IF :pCdCalculoContinua = 1 THEN
          :pCdCalculoContinua := PKGPAG_VAR.vgCalculo.cdCalculo;
          RETURN;
        END IF;
        
    ELSE
       pContinua (pcalculoretorno, vflcalculodefinitivo, pdtcalculo);

    END IF;
    
                                                                              
  ELSE
     xtmpag_tar.pentrarcalculoindividual(pcdfolhapagamento => pcdfolhapagamento,
                                         pcdvinculo => pcdvinculo,
                                         pdtcalculo => pdtcalculo,                                    
                                         pflcalculodefinitivo => vflcalculodefinitivo,
                                         pcalculoretorno => pxcalculoretorno);
     
     pcalculoretorno.CdMensagem := pxcalculoretorno.CdMensagem;
  
  END IF;

                                 
     DBMS_OUTPUT.put_line ('Vinculo ' || pCdVinculo || ', cdFolhaPagamento ' || pCdFolhaPagamento || ', CdOrgao ' || pCdOrgao || ', Retorno ->' || pcalculoretorno.CdMensagem);  
 
     DBMS_OUTPUT.put_line (pcalculoretorno.DeParametros); 
      
     IF pcalculoretorno.CdMensagem not in (0,4050) THEN

        DBMS_OUTPUT.put_line ('*** Deu Erro ' || pcalculoretorno.CdMensagem ||  ' - Calculado as ' || to_Char(vdthcalc,'hh24:mi:ss') );  
        
        FOR e IN (select dtinclusao, delog
                    from EPagLogProcessamento
                   where cdfolhapagamento = pcdfolhapagamento
                     and cdhistoricoparamcalculo = 0
                     and dtInclusao >= vdthcalc
                   ORDER BY dtInclusao dESC) LOOP
           DBMS_OUTPUT.PUT_LINE (to_Char(e.dtinclusao,'hh24:mi:ss') || ':');
           DBMS_OUTPUT.PUT_LINE (e.delog);
        END LOOP;
 
     
        RETURN;   
     END IF;
   
     dbms_output.put_line ('select r.nurubricafmt || ''-'' || lpad ( nusufixorubrica,2,''0'') as Rubrica, r.derubricaagrupamentofmt as descricao, vlindicerubrica, vlpagamento, h.cdrubricaagrupamento
 from epaghistoricorubricavinculo h
inner join vpagrubricaagrupamento r
   on r.cdrubricaagrupamento = h.cdrubricaagrupamento
 where cdVinculo = ' || pCdVinculo || ' and cdFolhaPagamento = ' || pCdFolhaPagamento || ' order by r.cdtiporubrica,r.nurubrica,h.nusufixorubrica');    

     DBMS_OUTPUT.PUT_LINE ( 'Rotina ' || case when :pFlCalculoAntigo = 0 then 'Nova' else 'Antiga' end );
     DBMS_OUTPUT.PUT_LINE (' RUBRICA   DESCRICAO                                  INDICE      VALOR    CDRUBAGRUP   LANC FINANC   DT ULT ALTERACAO');
     
     FOR rec in (select r.nurubricafmt || '-' || lpad ( nusufixorubrica,2,'0') as Rubrica, r.derubricaagrupamentofmt as descricao, vlindicerubrica, vlpagamento, h.cdrubricaagrupamento, h.cdlancamentofinanceiro, H.DTULTALTERACAO
                   , h.deexpressao
                   from epaghistoricorubricavinculo h
                  inner join vpagrubricaagrupamento r
                     on r.cdrubricaagrupamento = h.cdrubricaagrupamento
                   where cdVinculo = pCdVinculo and cdFolhaPagamento = pCdFolhaPagamento order by r.cdtiporubrica,r.nurubrica,h.nusufixorubrica) LOOP
                   

       DBMS_OUTPUT.PUT_LINE (rec.Rubrica || ' ' ||
                             rpad (rec.Descricao,35,' ') || ' ' ||
                             lpad (nvl(to_char(rec.vlindicerubrica), ' '),10,' ') || ' ' ||
                             lpad (rec.vlpagamento,13,' ') || '    ' ||
                             lpad (rec.cdrubricaagrupamento,10,' ') || '       ' || 
                             rec.cdlancamentofinanceiro
                             || '  ' 
                          ||  rec.deexpressao                
                             );
                   
    END LOOP;
       
  END;

  PROCEDURE PPRINCIPAL (PCdVinculo IN INTEGER) IS  
     vCdFolhaSim   INTEGER;
    begin

     select v.CdOrgao,  tf.cdtipofolhapagamento
       into pCdOrgao, pCdTipoFolhaPagamento
       from ecadvinculo v
       inner join vcadorgao o
         on o.cdorgao = v.cdorgao
       inner join epagtipofolhapagamento tf
         on cdtipofolhapagamento = :pcdtipofolhapagamento
        and tf.cdagrupamento = o.cdagrupamento      
      where cdvinculo = pcdVinculo;
      
     If :pCdForcarOrgao IS NOT NULL THEN
        pCdOrgao := :pCdForcarOrgao;  
     END IF; 
      
     select CdFolhaPagamento, DtCalculo , flcalculodefinitivo
       into pCdFolhaPagamento, pDtCalculo, vflcalculodefinitivo
       from epagfolhapagamento 
     where nuAnoMEsReferencia = :pNuAnoMesReferencia
      and cdtipofolhapagamento = :pCdTipoFolhaPagamento 
      and cdtipocalculo = :pcdTipoCalculo
      and cdOrgao = pCdOrgao
      and (nusequencialfolha = :pNuSequencialFolha OR :pNuSequencialFolha IS NULL);
      
      IF vflcalculodefinitivo = 'S' THEN
         dbms_output.put_line ('Calculo já está definitivo');
         raise NO_DATA_FOUND;
      END IF;

     PCalcula (pCdVinculo => pCdVinculo);
     
     IF :pCopiarSimulacao IN ('X','x') AND :pFlCalculoAntigo = 1 THEN
        
         SELECT FS.CdFolhaPagamento
           INTO vCdFolhaSim
           FROM EPAGFolhaPagamento FC
          INNER JOIN EPAGFOLhapagamento FS
             ON FS.CdOrgao = FC.CdOrgao
            AND FS.NuAnoMesReferencia = FC.NuAnoMesReferencia
            AND FS.CdTipoFolhaPagamento = FC.CdTipoFolhaPagamento
            AND FS.NuSequencialFolha = FC.NuSequencialFolha + 100
            AND FS.CDTipoCalculo = 2
          WHERE FC.CdFolhaPagamento = pcdFolhaPagamento;

         DELETE EPagHistoricoRubricaVinculo
          WHERE CdVinculo = pCdVinculo AND CdFolhaPagamento = vCdFolhaSim;

          DELETE EPagHistoricoRubricaRelVinc 
          WHERE CdVinculo = pCdVinculo AND CdFolhaPagamento = vCdFolhaSim;
         
         DELETE EPagCapaHistRubricaVinculo
          WHERE CdVinculo = pCdVinculo AND CdFolhaPagamento = vCdFolhaSim;

          
         UPDATE EPagHistoricoRubricaVinculo set CdFolhaPagamento = vCdFolhaSim
          WHERE CdVinculo = pCdVinculo AND CdFolhaPagamento = pCdFolhaPagamento;

          UPDATE EPagHistoricoRubricaRelVinc set CdFolhaPagamento = vCdFolhaSim
          WHERE CdVinculo = pCdVinculo AND CdFolhaPagamento = pCdFolhaPagamento;
         
         UPDATE EPagCapaHistRubricaVinculo set CdFolhaPagamento = vCdFolhaSim
          WHERE CdVinculo = pCdVinculo AND CdFolhaPagamento = pCdFolhaPagamento;
                    
        
          DBMS_OUTPUT.put_line ('Folha movida de ' || pCdFolhaPagamento || ' para simulação = ' || vCdFolhaSim);
          
     END IF;

END;

BEGIN
   
   vTabParam := PKGSOCUtil.FSplit (pString => :pLstVinculo, pSeparador => ',');

   For rec in vTabParam.FIRST .. vTabParam.LAST LOOP
       
      vCdVinculo := vTabParam(rec);
      
      PPRINCIPAL (pCdVinculo => vCdVinculo);
   
      commit;
      
   END LOOP;
   
/*

select cdhistoricoparamcalculo ,qtpessoas, qtpessoascalculadas
 from   epaghistoricoparamcalculo 
where cdtipocalculo = 12;


  
SELECT 
  cdvinculo, 
  r.cdrubricaagrupamento,
  r.cdtiporubrica,
  r.nurubrica,
  nusufixorubrica,
  r.derubricaagrupamento,
  Svlpagamento, 
  Svlindicerubrica,
  Dvlpagamento, 
  Dvlindicerubrica 
        
  FROM vPAgRubrica r,
  ( SELECT 
      cdrubricaagrupamento, 
      cdvinculo, 
      nusufixorubrica,
      SUM (DECODE (cdtipocalculo,12,null,vlpagamento)) as  Svlpagamento, 
      SUM (DECODE (cdtipocalculo,12,null,vlindicerubrica)) as  Svlindicerubrica,
      SUM (DECODE (cdtipocalculo,12,vlpagamento,null)) as  Dvlpagamento, 
      SUM (DECODE (cdtipocalculo,12,vlindicerubrica,null)) as  Dvlindicerubrica  
      FROM epaghistoricorubricavinculo h,
      (select cdfolhapagamento, cdtipocalculo from epagfolhapagamento
                                              where cdtipofolhapagamento = 2
                                                and ( cdtipocalculo = 12 or (cdtipocalculo = 5 and nusequencialfolha = 7) ) 
                                                and nuanomesreferencia = 201402 and cdorgao = 42 ) fp                                                   
      where h.cdfolhapagamento = fp.cdFolhaPagamento 
     --  and cdvinculo = 575573
       AND EXISTS ( select 1 from epaghistoricoparamcalcpessoa P WHERE CDHISTORICOPARAMCALCULO = 59922 AND P.CDVINCULO = H.CDVINCULO)
      group by cdrubricaagrupamento, 
      cdvinculo, 
      nusufixorubrica
   ) h
   WHERE r.cdrubricaagrupamento = h.cdrubricaagrupamento
    AND ( nvl(Svlpagamento,0) <> nvl(Dvlpagamento,0)  OR Svlindicerubrica <> Dvlindicerubrica)
   -- AND H.CDRUBRICAAGRUPAMENTO NOT IN (8323,8031)
   -- and r.cdtiporubrica <> 9    
    
    */                
end;
10
plstVinculo
1
636246
5
pNuAnoMesReferencia
1
202505
3
pCdTipoFolhaPagamento
1
907
3
pNuSequencialFolha
0
3
pcdTipoCalculo
1
1
3
pFlCalculoAntigo
1
0
3
pCdCalculoContinua
1
0
3
pCdForcarOrgao
0
3
pcdVinculo
0
-5
pCopiarSimulacao
0
5
0
