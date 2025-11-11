declare
   vHrv    epaghistoricorubricavinculo%rowtype;

begin
   FOR rec IN (
      
         select cdhrubricavinculo_origem,cdhrubricavinculo_teste, FP.cdfolhaorigem, Fp.cdfolhateste
           from ecmpacertorubrica ac
          inner join eCmpResumo z
             on z.NmCmp = 'NORMAL'
            and z.cdVinculo = ac.cdVinculo
            and z.cdRubricaAgrupamento = ac.CdRubricaAgrupamento
            and z.cdOrgao = ac.CdOrgao
            and z.nusufixorubrica = to_number(ac.nusufixorubrica)
          
          INNER JOIN ( 
          
             SELECT PARM.CdOrgao,
                    MAX(CASE  
                    WHEN (    FP.NuAnoMesReferencia = PARM.NuAnoMesRefOrigem
                            AND FP.Cdtipofolhapagamento = PARM.CdTipoFolhaPagOrigem
                            AND FP.cdTipoCalculo = PARM.CDTIPOCALCULOOrigem 
                            AND ( FP.Nusequencialfolha = PARM.Nusequencialorigem OR  PARM.Nusequencialorigem IS NULL)                                          
                          ) THEN
                         CdFolhaPagamento
                    ELSE
                         NULL
                    END) As CdFolhaOrigem,
                    
                    MAX(CASE  
                    WHEN (    FP.NuAnoMesReferencia = PARM.NuAnoMesRefteste
                            AND FP.Cdtipofolhapagamento = PARM.CdTipoFolhaPagteste
                            AND FP.cdTipoCalculo = PARM.CDTIPOCALCULOteste 
                            AND ( FP.Nusequencialfolha = PARM.Nusequencialteste OR  PARM.Nusequencialteste IS NULL)                                          
                          ) THEN
                         CdFolhaPagamento
                    ELSE
                         NULL
                    END) As CdFolhaTeste
                                         
                  FROM ECmpParam PARM
                                          
                  INNER JOIN EPAGFOLHAPAGAMENTO FP
                     ON  ( (    FP.NuAnoMesReferencia = PARM.NuAnoMesRefOrigem
                            AND FP.Cdtipofolhapagamento = PARM.CdTipoFolhaPagOrigem
                            AND FP.cdTipoCalculo = PARM.CDTIPOCALCULOOrigem 
                            AND ( FP.CdOrgao = PARM.cdOrgao OR PARM.CdOrgao IS NULL)
                            AND ( FP.Nusequencialfolha = PARM.Nusequencialorigem OR  PARM.Nusequencialorigem IS NULL)
                           ) OR
                           (    FP.NuAnoMesReferencia = PARM.NUANOMESREFTeste
                            AND FP.Cdtipofolhapagamento = PARM.CdTipoFolhaPagTeste
                            AND FP.cdTipoCalculo = PARM.CdtipocalculoTeste
                            AND ( FP.CdOrgao = PARM.cdOrgao OR PARM.CdOrgao IS NULL)
                            AND ( FP.Nusequencialfolha = PARM.NusequencialTeste OR  PARM.NusequencialTeste IS NULL)
                           )
                         )                                 
                         
                  WHERE Parm.NmCmp = 'NORMAL'
                  group by PARM.CdOrgao          
             ) FP    
             on fp.cdorgao = ac.cdorgao      
            
          where ac.Flcalculo = 'N' and ac.flvigente = 'S' and ac.nmCmp = 'NORMAL'
            and z.tem_dif = 1
            
            
            ) LOOP
 
      IF rec.cdhrubricavinculo_origem = 0 THEN -- excluir
         
         DELETE EPAGHISTORICORUBRICAVINCULO WHERE CdHistoricoRubricaVinculo = rec.cdhrubricavinculo_teste;
         
      ELSE

         SELECT *
           INTO vHrv
           FROM EPAGHISTORICORUBRICAVINCULO  
          WHERE CdHistoricoRubricaVinculo = rec.cdhrubricavinculo_origem;
                             
         IF rec.cdhrubricavinculo_teste = 0 THEN -- incluir      

             vHrv.cdFolhaPagamento          := rec.cdfolhateste;
             vHrv.CdHistoricoRubricaVinculo := SPAGHISTORICORUBRICAVINCULO.NEXTVAL;
         
             INSERT INTO EPAGHISTORICORUBRICAVINCULO Values vHRV;

         ELSE -- alterar

             UPDATE EPAGHISTORICORUBRICAVINCULO 
                SET VlPAgamento     = vHrv.VlPagamento,
                    VlIndiceRubrica = vHrv.VlIndiceRubrica 
             WHERE CdHistoricoRubricaVinculo = rec.cdhrubricavinculo_teste;
              
         END IF;
         
      END IF;
       
   END LOOP;
     
end;

