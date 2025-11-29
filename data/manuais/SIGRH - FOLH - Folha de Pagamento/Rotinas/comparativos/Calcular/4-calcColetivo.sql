declare
   C_AGENDAR        INTEGER := 0;
   pFlCalculoAntigo INTEGER := 0;
   
   vCdTarefa       integer;
   vCdHist         integer;
   vCdAgendamento  integer;
   vDtIni          DATE;
   vFolAnt         EPAGFOLHAPAGAMENTO%ROWTYPE;
   vFlQuebraOrgao  INTEGER := 0;
 
/*
-- Reagendar proxima tarefa
begin  PKGCMP.PReagendarProxima (pCdTarefa => NULL); end;

*/  
   
   CROT_CALCULO_ANTIGO   CONSTANT VARCHAR2(11) := '11111111111';
   CROT_CALCULO_NOVO     CONSTANT VARCHAR2(11) := '22222222222';
begin
   dbms_output.put_line ('-- Reagendar proxima tarefa');
   dbms_output.put_line ('begin PKGCMP.PReagendarProxima (pCdTarefa => NULL); end;');                                 
                                    
   FOR rec IN ( SELECT g.*
                                                        
                  FROM (select t.*,
                                DECODE(FlCalculoDefinitivo,'S',NVL(fp.DeOrdemExecucao,'D9999'),'N'), 
                                  CASE
                                     WHEN tf.CdTipoFolha in  (-- Adiantamentos
                                                              PKGPAG_TIPO.cnTpFolhaAdiant13Ctisp,
                                                              PKGPAG_TIPO.cnTpFolhaAdiant13,
                                                              PKGPAG_TIPO.cnTpFolhaAposAdiant13) then
                                          1
                                                                                
                                     WHEN tf.CdTipoFolha in  (--- Rescisoes
                                                              PKGPAG_TIPO.cnTpFolhaRescisao,
                                                              PKGPAG_TIPO.cnTpFolhaRescisaoEstagiario,
                                                              PKGPAG_TIPO.cnTpFolhaRescisaoPesquisador) then

                                          2
                                                   
                                     WHEN tf.CdTipoFolha in  (--- Ferias
                                                              PKGPAG_TIPO.cnTpFolhaFerias) then
                                          decode (fp.cdAgrupamento,4,0,3)
                                                   

                                     WHEN tf.CdTipoFolha in  (-- Normal
                                                              PKGPAG_TIPO.cnTpFolhaNormal,
                                                              PKGPAG_TIPO.cnTpFolhaComissionadoPuro,
                                                              PKGPAG_TIPO.cnTpFolhaBolsista,
                                                              PKGPAG_TIPO.cnTpFolhaResidente,
                                                              PKGPAG_TIPO.cnTpFolhaPesquisador,
                                                              PKGPAG_TIPO.cnTpFolhaConvenio,
                                                              PKGPAG_TIPO.cnTpFolhaCtisp,
                                                              PKGPAG_TIPO.cnTpFolhaAposentadoria,
                                                              PKGPAG_TIPO.cnTpFolhaInstPensao,
                                                              PKGPAG_TIPO.cnTpFolhaFunebre,
                                                              PKGPAG_TIPO.cnTpFolhaServAfast) then
                                          4                             

                                     WHEN tf.CdTipoFolha in  (--- dec terc de normal
                                                              PKGPAG_TIPO.cnTpFolha13,
                                                              PKGPAG_TIPO.cnTpFolhaResidente13,
                                                              PKGPAG_TIPO.cnTpFolhaCtisp13,
                                                              PKGPAG_TIPO.cnTpFolhaAposentadoria13,
                                                              PKGPAG_TIPO.cnTpFolhaFunebre13) then
                                          5                             

                                     WHEN tf.CdTipoFolha in  (--- Outras
                                                              PKGPAG_TIPO.cnTpFolhaOutras,
                                                              PKGPAG_TIPO.cnTpFolhaBEP,
                                                              PKGPAG_TIPO.cnTpFolhaProdex13,
                                                              PKGPAG_TIPO.cnTpFolhaHonorarios13,
                                                              PKGPAG_TIPO.cnTpFolhaHonorarProcuradores13) then 
                                          6
                                     else
                                          9
                                  end as ordem1,
                                  decode (fp.cdAgrupamento,276,001,176,002,134,003,1,004,3,005,132,006,5,007,4,008,2,009,136,010,6,011,099) as ordem2,
                                  decode(fp.cdorgao, 43, 990, 87, 72, fp.cdorgao) as ordem3 ,
                                  fp.cdTipoFolhaPagamento as ordem4, 
                                  fp.NuSequencialFolha as ordem5                                      
                                                    
                           from (   
                                    
                                    select distinct cdagrupamento, 
                                           cdtipocalculo,  
                                           cdtipofolhapagamento, 
                                           numesreferencia, 
                                           nuanoreferencia, 
                                           nusequencialfolha, 
                                           dtcalculo,
                                           cdorgao,
                                           cdvinculo,
                                           dtprevisaocredito,
                                           cdpessoa,
                                           cdfolhapagamento
                                      from tmpxpes  
                                                        
                                 ) t
                                          
                          inner join epagfolhapagamento FP
                             on fp.cdFolhaPagamento = t.cdfolhapagamento       
                          inner join epagTipoFolhaPagamento tf
                             on tf.cdTipoFolhaPagamento = fp.cdTipoFolhaPagamento  
                     ) g
                                        
                 order by ordem1,ordem2, ordem3, ordem4, ordem5, cdorgao, cdvinculo 

                     ) LOOP    

      IF vFolAnt.cdTipoFolhaPagamento IS NULL
         OR ( vFolAnt.cdTipoFolhaPagamento <> rec.cdTipoFolhaPagamento OR
              vFolAnt.NuSequencialFolha <> rec.NuSequencialFolha ) THEN -- quebrou hpc
            
         vDtIni  := SYSDATE + 1 * (1/(24*60));
         
         IF C_AGENDAR = 1 THEN
            insert into eadmagendamento
              (cdagendamento, 
               cdtipotarefa, 
               cdperiodicidade, 
               nmagendamento, 
               dtvalidadeinicio, 
               dtinicio, 
               nucpf)
            values
              (sadmagendamento.nextval, --cdagendamento, 
              6, -- cdtipotarefa, 
              4, -- cdperiodicidade, 
              'calc folha', -- nmagendamento, 
              vdtini, -- dtvalidadeinicio, 
              vdtini, -- dtinicio, 
              '11111111111' -- nucpf, 
              )
            returning CdAgendamento into vCdAgendamento;

            insert into eadmtarefa
               (cdtarefa, 
                cdagendamento, 
                cdsituacaotarefa, 
                dtinicio)
            values     
               (sAdmTarefa.nextval, -- cdtarefa, 
                vCdAgendamento, --cdagendamento, 
                1, -- cdsituacaotarefa, 
                vDtIni)
            RETURNING CdTarefa INTO vCdTarefa;
         
         END IF;
                           
      insert into epaghistoricoparamcalculo
          ( cdhistoricoparamcalculo, 
            cdagrupamento, 
            cdtipocalculo,  
            cdtipofolhapagamento, 
            flprocessaagrupamento, 
            fldefinitivo,  
            numescompetencia, 
            nuanocompetencia, 
            nusequencial, 
            dtcalculo, 
            flpagaadiantamento13sal, 
            instatus, 
            nucpfcadastrador, 
            dtinclusao, 
            cdtarefa, 
            dtprocessamento, 
            dtprevistacredito, 
            flsalvarvalorescalculovigente, 
            flbloqnaorecadastrado)
       values (
            SPaghistoricoparamcalculo.nextval, -- dhistoricoparamcalculo, 
            rec.cdagrupamento,-- cdagrupamento, 
            rec.cdtipocalculo,-- cdtipocalculo,  
            rec.cdtipofolhapagamento,-- cdtipofolhapagamento, 
            'S',-- flprocessaagrupamento, 
            'N',-- fldefinitivo,  
            rec.numesreferencia,-- numescompetencia, 
            rec.nuanoreferencia,-- nuanocompetencia, 
            rec.nusequencialfolha,-- nusequencial, 
            rec.dtcalculo,-- dtcalculo, 
            'N',-- flpagaadiantamento13sal, 
            0,-- instatus, 
            decode (pFlCalculoAntigo,1,CROT_CALCULO_ANTIGO,CROT_CALCULO_NOVO), --nucpfcadastrador, 
            sysdate, --dtinclusao, 
            vCdTarefa, --cdtarefa, 
            vDtIni, --dtprocessamento, 
            rec.dtprevisaocredito, --dtprevistacredito, 
            'N', --flsalvarvalorescalculovigente, 
            'N' --flbloqnaorecadastrado
            )
        returning CdHistoricoParamCalculo into vCdHist;
      
        DBMS_OUTPUT.PUT_LINE ('select * from vpagcalculo where cdhistoricoparamcalculo >= ' || vCdHist || ';');
     
        vFolAnt.cdTipoFolhaPagamento := rec.cdTipoFolhaPagamento;
        vFolAnt.NuSequencialFolha    := rec.NuSequencialFolha;
           
        vFlQuebraOrgao := 1;
        
      end if;
    
      IF vFlQuebraOrgao = 1 OR 
         ( vFolAnt.cdOrgao <> rec.cdOrgao ) THEN -- quebrou orgao
             
         insert into epaghistoricoparamcalculoorgao
           values (vCdHist,
                   rec.CdOrgao,
                   1,
                   0,
                   0,
                   null,
                   null);

         vFlQuebraOrgao  := 0;
         vFolAnt.cdOrgao := rec.cdOrgao;
         
      END IF;
      
      begin
         insert into EPagHistoricoParamCalcPessoa 
           values
            (vCdHist,
             rec.cdVinculo,
             rec.cdPessoa);          
      exception
         when others then  null;
                 
      end;
      
   END LOOP; 
            
   commit;
   
end;


