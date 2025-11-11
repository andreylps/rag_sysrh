PL/SQL Developer Test script 3.0
101
declare 

  vINSSControle  PKGPAG_INSS.rINSSControle;  
  vINSS          NUMBER;
  vPasso         INTEGER := 6;
begin
  -- Test statements here

  vINSSControle := PKGPAG_INSS.FInicializarControle;
  
  FOR rec in ( select 
                  level as ordem,
                  case 
                     when level <= 2 then
                        2000
                     when level = 6 then
                        3500
                     else
                        2000 + trunc((level - 1)/ 2) * 1000
                  end as vlBaseCalculoNormal,
                  case 
                     when level <= 2 then
                        2000
                     when level = 6 then
                        500
                     else
                        1000
                  end as vlBaseCalculoSup,
                  decode (level, 1,157.23,2,216.17,3,136.17,4,140,5,140,70) as vlINSS,
                  case when MOD(level, 2) = 0  then
                       2
                    else
                       1
                  end as cdorgao,
                  case when MOD(level, 2) = 0  then
                       20
                    else
                       10
                  end as cdvinculo,
                  case when level <= 2 then
                       1
                    else
                       5
                   end as cdtipocalculo,
                   99 as CdTipoFolhaPagamento,
                   decode (level,1,0,2,0,3,40,4,-40,5,60,6,-60) as inssacerto,
                   decode (level,1,0,2,0,3,333.33,4,-285.7,5,122.51,6,-142) as baseacerto                       
                        
               from dual
               connect by level <= 6
               order by level
               ) LOOP

 
      IF rec.ordem <= 2 THEN -- Folha Normal
            
         PKGPAG_INSS.PCalcularNormal (pINSSControle         => vINSSControle,
                                      pNuAnoMes             => 202501,
                                      pCdOrgao              => rec.cdorgao,
                                      pCdVinculo            => rec.cdvinculo,
                                      pCdTipoFolhaPagamento => 99,
                                      pVlBaseCalculo        => rec.vlBaseCalculoNormal                               
                                      );
      ELSE -- Recalculo
                                   
         PKGPAG_INSS.PCalcularRecalculo (pINSSControle         => vINSSControle,
                                         pNuAnoMes             => 202501,
                                         pCdOrgao              => rec.cdorgao,
                                         pCdVinculo            => rec.cdvinculo,
                                         pCdTipoFolhaPagamento => 99,
                                         pVlBaseCalculo        => rec.vlBaseCalculoNormal                              
                                        );
     
      END IF;

  
      FOR res IN vINSSControle.calc.FIRST .. vINSSControle.calc.LAST LOOP
       
        DBMS_OUTPUT.PUT_LINE ( rec.ordem || ' - Ref: ' || vINSSControle.calc(res).NuAnoMes || case when vINSSControle.calc(res).FlDecTerceiro = 1 then '_13' else null end 
        || ' Base Calculo: ' ||  vINSSControle.calc(res).vlBaseCalculo || ' INSS: ' || vINSSControle.calc(res).vlINSS 
           || ' Base de Acerto: ' || vINSSControle.calc(res).VlBaseAcerto || '  INSS Acerto: ' || vINSSControle.calc(res).VlINSSAcerto 

        );
         
      END LOOP;
                     
      PKGPAG_INSS.PDadosAnteriores (pINSSControle         => vINSSControle,
                                    pNuAnoMes             => 202501,
                                    pCdOrgao              => rec.cdorgao,
                                    pCdVinculo            => rec.cdvinculo,
                                    pCdTipoFolhaPagamento => rec.CdTipoFolhaPagamento,
                                    pCdTipoCalculo        => rec.cdtipocalculo,
                                    pVlBaseCalculo        => rec.vlbasecalculoSup,
                                    pVlBaseAcerto         => rec.BaseAcerto,
                                    pVlINSS               => rec.vlinss);
   
                                  
   END LOOP;


end;
0
0
