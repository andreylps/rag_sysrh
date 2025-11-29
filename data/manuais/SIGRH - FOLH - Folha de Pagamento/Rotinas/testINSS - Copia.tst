PL/SQL Developer Test script 3.0
39
declare 

  vINSSControle  PKGPAG_INSS.rINSSControle;  
  vINSS          NUMBER;
begin
  -- Test statements here

  vINSSControle := PKGPAG_INSS.FInicializarControle;

  PKGPAG_INSS.PCalcularNormal (pINSSControle     => vINSSControle,
                               pNuAnoMes         => 202501,
                               pVlBaseCalculo    => 2000);
                               
  PKGPAG_INSS.PCalcularNormal (pINSSControle     => vINSSControle,
                               pNuAnoMes         => 202502,
                               pVlBaseOrgaosAnt  => 2000,
                               pVlBaseCalculo    => 2000);
                               
                                 
  PKGPAG_INSS.PCalcularRecalculo (pINSSControle     => vINSSControle,
                                  pNuAnoMes         => 202503,
                                  pVlBaseCalculo    => 3000, 
                                  pVlBaseOrgaosPos  => 2000,
                                  pVlBaseNormal     => 1000000,
                                  pVlINSSNormal     => 111157.23
                                  );

 
  FOR rec IN vINSSControle.pes.FIRST .. vINSSControle.pes.LAST LOOP
    
     DBMS_OUTPUT.PUT_LINE ( 'Ref: ' || vINSSControle.pes(rec).NuAnoMes || case when vINSSControle.pes(rec).FlDecTerceiro = 1 then '_13' else null end 
     || ' Base Calculo: ' ||  vINSSControle.pes(rec).vlBaseCalculo || ' INSS: ' || vINSSControle.pes(rec).vlINSS 
        || ' Base de Acerto: ' || vINSSControle.pes(rec).VlBaseAcerto || ' para INSS: ' || vINSSControle.pes(rec).VlINSSAcerto 

     );
      
  END LOOP;
  
end;
0
0
