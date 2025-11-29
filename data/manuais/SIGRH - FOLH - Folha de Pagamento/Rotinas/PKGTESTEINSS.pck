create or replace package PKGTESTEINSS is

PROCEDURE PMain;

end PKGTESTEINSS;
/
create or replace package body PKGTESTEINSS is

  cNuAnoMes     INTEGER := 202501;

TYPE rINSSResult IS RECORD 
(
   VlINSS                  NUMBER(13,2),
   VlSomaAcerto            NUMBER(13,2),
   FlMultOrgao             INTEGER
);


TYPE rINSSAliquota IS RECORD
(    
   VlInicial               number(13,2),
   VlFinal                 number(13,2),
   VlAliquota              number(10,4),
   VlUtilizado             number(13,2)  
);

TYPE tINSSAliquota IS TABLE OF rInssAliquota;        

TYPE rINSSFaixa IS RECORD (
   NuAnoMesIni             INTEGER,
   NuAnoMesFim             INTEGER,
   VlTeto                  NUMBER(13,2),
   VlAliqIndiv             NUMBER(4,2),
   aliquota                tINSSAliquota
);
    
TYPE tINSSFaixa IS TABLE OF rINSSFaixa INDEX BY PLS_INTEGER;        
   

TYPE rINSSFaixaTratada IS RECORD 
(
   faixa                   rINSSFaixa,
   vlSomaAcerto            NUMBER (13,2),
   vlTributado             NUMBER (13,2),
   flMultOrgao             INTEGER
);

TYPE rINSSCalculo IS RECORD (
   NuAnoMes             INTEGER,
   FlDecTerceiro        INTEGER,
   FlRecalculo          INTEGER,
   CdOrgao              INTEGER,
   CdVinculo            INTEGER,
   CdTipoFolhaPagamento INTEGER,
   FlContribIndiv       INTEGER,
   FlAcerto             INTEGER,
   VlBaseCalculo        NUMBER (13,2),
   VlINSS               NUMBER (13,2),
   VlBaseAcerto         NUMBER (13,2),
   VlINSSAcerto         NUMBER (13,2)      
);
    
TYPE tINSSCalculo IS TABLE OF rINSSCalculo;        
         
TYPE rINSSOrdem IS RECORD (
   FlDecTerceiro        INTEGER,
   NuAnoMes             INTEGER,
   CdOrgao              INTEGER,
   CdVinculo            INTEGER,
   CdTipoFolhaPagamento INTEGER,
   CdTipoCalculo        INTEGER,
   VlBaseCalculo        NUMBER (13,2),
   VlINSS               NUMBER (13,2),
   FlContribIndiv       INTEGER,
   VlBaseAcerto         NUMBER (13,2),
   VlINSSAcerto         NUMBER (13,2) 
);   

TYPE tINSSOrdem IS TABLE OF rINSSOrdem; 

TYPE rINSSTipoAnoMes IS RECORD (
   FlMultOrgao       INTEGER,
   ordem             tINSSOrdem
);   

TYPE tINSSTipoAnoMes IS table of rINSSTipoAnoMes
   INDEX BY PLS_INTEGER; 

TYPE rINSSControle IS RECORD
(
   faixa                   tINSSFaixa,
   calc                    tINSSCalculo,
   anterior                tINSSTipoAnoMes
   
);  
FUNCTION FObterFaixaTratada (pINSSControle IN rINSSControle, pINSSCalculo IN rINSSCalculo) RETURN rINSSFaixaTratada IS 
   
   vINSSFaixaTratada  rINSSFaixaTratada;  
   vIndOrdem          INTEGER;
   vSair              BOOLEAN;
   vINSSOrdem         rINSSOrdem;
   vAliquota          rINSSAliquota;
   vlDisponivel       NUMBER(13,2);
   vlUtilizado        NUMBER(13,2);
   vlAnalisado        NUMBER(13,2);
   vChaveTipoAnoMes   INTEGER;
   vFlFolhaDesprezar  BOOLEAN;
   vTabOrdem          tINSSOrdem;
   
   PROCEDURE PImprimir IS
      vTotalUtilizado   NUMBER;
      
   BEGIN
      
      vTotalUtilizado := 0;
  
      FOR aliq IN vINSSFaixaTratada.faixa.aliquota.FIRST .. vINSSFaixaTratada.faixa.aliquota.LAST LOOP  
         
         vAliquota := vINSSFaixaTratada.faixa.aliquota(aliq);
         
       --  dbms_output.put_line ('Faixa ' || aliq || ' (' || vAliquota.vlInicial || 
       --  '-' || vAliquota.vlFinal || ') Utilizado = ' || vAliquota.vlUtilizado);
         
         vTotalUtilizado := vTotalUtilizado + vAliquota.vlUtilizado;

      END LOOP;
     
   --   dbms_output.put_line ('Total Utilizado = ' ||  vTotalUtilizado);
 
    
   END;
   
   PROCEDURE PAcumularTabOrdemAcerto IS
      
      vOrdem     rINSSOrdem; 
      TYPE tIntIndex IS TABLE OF PLS_INTEGER INDEX BY PLS_INTEGER;
      vTabOrgao  tIntIndex;  
      vInd       INTEGER;
      vFlAcum    BOOLEAN;
      
   BEGIN
      vTabOrgao.DELETE;
      vTabOrdem := tINSSOrdem();
      vFlAcum   := TRUE;
      
      FOR rec IN pINSSControle.anterior(vChaveTipoAnoMes).ordem.FIRST .. pINSSControle.anterior(vChaveTipoAnoMes).ordem.LAST LOOP
         
         vOrdem := pINSSControle.anterior(vChaveTipoAnoMes).ordem(rec);
         
         IF pINSSCalculo.CdOrgao = vOrdem.cdOrgao THEN -- é do orgao que estou calculando, pára de acumular orgaos novos
            vINSSFaixaTratada.VlSomaAcerto := vINSSFaixaTratada.VlSomaAcerto + vOrdem.VlBaseAcerto;
            vFlAcum := FALSE;
         ELSE
            
            IF NOT vTabOrgao.EXISTS (vOrdem.cdOrgao) THEN
               IF vFlAcum THEN 
                  vTabOrdem.EXTEND;
                  vInd := vTabOrdem.LAST;
                  vTabOrgao (vOrdem.cdOrgao) := vInd;
                  vTabOrdem(vInd) := vOrdem;
               END IF;
            ELSE
               -- somar no sequencial que já existia
               vInd := vTabOrgao (vOrdem.cdOrgao);
               vTabOrdem(vInd).vlBaseCalculo := vTabOrdem(vInd).vlBaseCalculo + vOrdem.VlBaseCalculo; 
            END IF;
         END IF;
      END LOOP;       
              
   END;
    
BEGIN
   
   vINSSFaixaTratada.VlSomaAcerto := 0;

   vINSSFaixaTratada.faixa := null; -- FRetornarFaixaINSS (pINSSControle => pINSSControle, pNuAnoMes => pINSSCalculo.NuAnoMes);

   vChaveTipoAnoMes := pINSSCalculo.NuAnoMes * 10 + pINSSCalculo.FlDecTerceiro;

   IF NOT pINSSControle.anterior.EXISTS(vChaveTipoAnoMes) THEN
      vIndOrdem     := NULL;
      vINSSFaixaTratada.FlMultOrgao  := 0;
   ELSE
      IF pINSSCalculo.FlAcerto = 1 THEN 
         PAcumularTabOrdemAcerto;
      ELSE
         vTabOrdem     := pINSSControle.anterior(vChaveTipoAnoMes).ordem;
      END IF;
      
      vIndOrdem     := vTabOrdem.FIRST;
      vINSSFaixaTratada.FlMultOrgao  := pINSSControle.anterior(vChaveTipoAnoMes).FlMultOrgao;
      IF vIndOrdem IS NOT NULL THEN
         vINSSOrdem := vTabOrdem (vIndOrdem);
      END IF;
   END IF;
 
   vINSSFaixaTratada.VlTributado := 0;

   FOR aliq IN vINSSFaixaTratada.faixa.aliquota.FIRST .. vINSSFaixaTratada.faixa.aliquota.LAST LOOP  
      
      vAliquota := vINSSFaixaTratada.faixa.aliquota(aliq);
       
      vlDisponivel := valiquota.VlFinal - valiquota.VlInicial + 0.01;  
   
      -- verificando valores utilizados
      
      vlUtilizado := 0;
      vSair := (vIndOrdem IS NULL);
      
      WHILE NOT vSair LOOP
               
         -- Verificar se é folha normal que está sendo recalculada e que deve liberar a faixa
         -- se for recalculo, deve repor o valor da normal que não será mais considerada 

         vFlFolhaDesprezar := FALSE;
         IF pINSSCalculo.FlRecalculo = 1 AND vINSSOrdem.CdOrgao = pINSSCalculo.CdOrgao AND vINSSOrdem.CdVinculo = pINSSCalculo.CdVinculo 
            AND vINSSOrdem.CdTipoFolhaPagamento = pINSSCalculo.CdTipoFolhaPagamento THEN
            vFlFolhaDesprezar := TRUE;
         END IF;

         IF vINSSOrdem.VlBaseCalculo > vlDisponivel THEN
            vlAnalisado := vlDisponivel;
            vINSSOrdem.VlBaseCalculo := vINSSOrdem.VlBaseCalculo - vlAnalisado;
            vSair := TRUE;
         ELSE
            vlAnalisado := vINSSOrdem.VlBaseCalculo;
            vIndOrdem   := vTabOrdem.NEXT(vIndOrdem);
            IF vIndOrdem IS NULL THEN
               vSair := TRUE;
            ELSE
               vINSSOrdem  := vTabOrdem (vIndOrdem);
            END IF;
         END IF;

         -- se for recalculo, deve repor o valor da normal que não será mais considerada 
         
         vlDisponivel := vlDisponivel - vlAnalisado;
         
         IF vFlFolhaDesprezar THEN
            NULL;
         ELSE
            vlUtilizado := vlUtilizado + vlAnalisado;
         END IF;
                     
      END LOOP;   
         
      -- Registrando disponibilidade
      
      vINSSFaixaTratada.VlTributado := vINSSFaixaTratada.VlTributado + vlUtilizado;
      
      vAliquota.vlUtilizado     := vlUtilizado;
      vINSSFaixaTratada.faixa.aliquota(aliq) := vAliquota;
      
   END LOOP;
  
   pImprimir;
  
   RETURN vINSSFaixaTratada;
END;

FUNCTION FCalcularINSS (pINSSCalculo IN rINSSCalculo, pINSSFaixaTratada IN rINSSFaixaTratada) RETURN rINSSResult IS

   vValorTributar    NUMBER;
   vValorFaixa       NUMBER;
   vINSSResult       rINSSResult;
   
BEGIN
   
   vINSSResult.VlINSS       := 0;   
   vINSSResult.VlSomaAcerto := pINSSFaixaTratada.vlSomaAcerto;
   vINSSResult.FlMultOrgao  := pINSSFaixaTratada.FlMultOrgao;
   
   IF pINSSFaixaTratada.VlTributado < pINSSFaixaTratada.faixa.VlTeto THEN

      vValorTributar := least (pINSSFaixaTratada.faixa.VlTeto , pINSSCalculo.VlBaseCalculo + pINSSFaixaTratada.VlTributado);   
      
      vValorTributar := vValorTributar - pINSSFaixaTratada.VlTributado;
       
      IF pINSSCalculo.FlContribIndiv = 1 THEN -- Calculo de percentual individual   

         vINSSResult.VlINSS := trunc(vValorTributar * pINSSFaixaTratada.faixa.VlAliqIndiv / 100,2);
          
      ELSE
         
         FOR i IN pINSSFaixaTratada.faixa.aliquota.FIRST .. pINSSFaixaTratada.faixa.aliquota.LAST LOOP
          
            vValorFaixa := (pINSSFaixaTratada.faixa.aliquota(i).VlFinal - pINSSFaixaTratada.faixa.aliquota(i).VlInicial + 0.01) - pINSSFaixaTratada.faixa.aliquota(i).VlUtilizado;

            IF vValorTributar < vValorFaixa then
               vValorFaixa := vValorTributar;
            END IF;
            
            vINSSResult.VlINSS := vINSSResult.VlINSS + trunc( (vValorFaixa * pINSSFaixaTratada.faixa.aliquota(i).VlAliquota)/100,2); 
            
            vValorTributar := vValorTributar - vValorFaixa;
            
            IF vValorTributar = 0 THEN
               EXIT;
            END IF;
           
         END LOOP;

      END IF;
   
   END IF;
     
   RETURN vINSSResult;
   
END;

PROCEDURE PRegistrarINSS (pINSSControle         IN OUT NOCOPY rINSSControle, 
                          pNuAnoMes             IN INTEGER,
                          pFlDecTerceiro        IN INTEGER DEFAULT 0,
                          pFlRecalculo          IN INTEGER,
                          pCdOrgao              IN INTEGER,
                          pCdVinculo            IN INTEGER,  
                          pCdTipoFolhaPagamento IN INTEGER,                      
                          pVlBaseCalculo        IN INTEGER,
                          pFlContribIndiv       IN INTEGER DEFAULT 0) IS

   vINSSCalculo        rINSSCalculo;
   vInd                INTEGER;
   vINSSResult         rINSSResult;
   vINSSFaixaTratada   rINSSFaixaTratada;
BEGIN
   
   vINSSCalculo.NuAnoMes             := pNuAnoMes;  
   vINSSCalculo.FlDecTerceiro        := pFlDecTerceiro;
   vINSSCalculo.FlRecalculo          := pFlRecalculo;
   vINSSCalculo.CdOrgao              := pCdOrgao;
   vINSSCalculo.CdVinculo            := pCdVinculo;   
   vINSSCalculo.CdTipoFolhaPagamento := pCdTipoFolhaPagamento;
   vINSSCalculo.VlBaseCalculo        := NVL(pVlBaseCalculo,0);
   vINSSCalculo.FlContribIndiv       := NVL(pFlContribIndiv,0);
   vINSSCalculo.FlAcerto             := 0;   
   vINSSCalculo.VlBaseAcerto         := 0;
   vINSSCalculo.VlINSSAcerto         := 0;
   
   vINSSFaixaTratada := FObterFaixaTratada (pINSSControle => pINSSControle, pINSSCalculo => vINSSCalculo);
  
   vINSSResult                       := FCalcularINSS (pINSSCalculo => vINSSCalculo, pINSSFaixaTratada => vINSSFaixaTratada);

   vINSSCalculo.vlINSS               := vINSSResult.vlINSS;
   
END;

FUNCTION FRetornaAliquotaINSS(pNuAnoReferencia IN INTEGER,
                              pNuMesReferencia IN INTEGER)
   RETURN PKGPAG_TIPO.rAliquotaINSS IS
   
   CURSOR cFaixa(pCdHistAliquotaINSS IN INTEGER) IS
      SELECT F.VlInicial,
             F.VlFinal,
             F.VlAliquota,
             F.VlParcelaDeducao,
             F.Flaliquotaprogressiva,
             hai.Vlaliqcontribindividual,
             hai.VLTETOCONTRIBINDIVIDUAL
        FROM EtrbaliquotafaixaINSS F
       INNER JOIN etrbhistaliquotainss hai
          ON hai.cdhistaliquotainss = f.cdhistaliquotainss
       WHERE F.CdHistAliquotaINSS = pCdHistAliquotaINSS
       ORDER BY F.VlInicial;
   
   vAliquotaINSS PKGPAG_TIPO.rAliquotaINSS;
   vFaixa        PKGPAG_TIPO.tFaixaAliquota;
   
BEGIN
   
   SELECT A.CdHistAliquotaINSS
     INTO vAliquotaINSS.CdHistAliquotaINSS
     FROM EtrbHistAliquotaINSS A
    WHERE ((A.nuAnoInicio < pNuAnoReferencia OR
          (A.nuAnoInicio = pNuAnoReferencia AND
          A.nuMesInicio <= pNuMesReferencia)) AND
          (A.nuAnoFinal > pNuAnoReferencia OR
          (A.nuAnoFinal = pNuAnoReferencia AND
          A.nuMesFinal >= pNuMesReferencia) OR A.nuAnoFinal IS NULL));
   
   OPEN cFaixa(vAliquotaINSS.CdHistAliquotaINSS);
   
   FETCH cFaixa BULK COLLECT
      INTO vFaixa;
   
   CLOSE cFaixa;
   
   IF vFaixa.COUNT > 0 THEN
      
      vAliquotaINSS.VlTeto := 0;
      
      FOR i IN vFaixa.FIRST .. vFaixa.LAST
         
       LOOP
         
         IF vAliquotaINSS.VlTeto < vFaixa(i).VlFinal THEN
            
            vAliquotaINSS.VlTeto := vFaixa(i).VlFinal;
            
         END IF;
         
      END LOOP;
      
      vAliquotaINSS.lFaixa := vFaixa;
      
      RETURN vAliquotaINSS;
      
   ELSE
      
      RETURN NULL;
      
   END IF;
   
EXCEPTION
   
   WHEN OTHERS THEN
      
      RETURN NULL;
      
END;

PROCEDURE PMain IS
  
  vINSSControle  PKGPAG_INSS.rINSSControle;  
  vINSS          NUMBER;
  vINSSResult    rINSSResult;  
  
BEGIN

   vINSSControle := PKGPAG_INSS.FInicializarControle;
     
   PKGPAG_VAR.vAliqINSS  := PKGPAG_GERAL.FRetornaAliquotaINSS( 2025, 07);
  
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
                                      pNuAnoMes             => cNuAnoMes,
                                      pCdOrgao              => rec.cdorgao,
                                      pCdVinculo            => rec.cdvinculo,
                                      pCdTipoFolhaPagamento => 99,
                                      pVlBaseCalculo        => rec.vlBaseCalculoNormal                               
                                      );
      ELSE -- Recalculo
                                   
         PKGPAG_INSS.PCalcularRecalculo (pINSSControle         => vINSSControle,
                                         pNuAnoMes             => cNuAnoMes,
                                         pCdOrgao              => rec.cdorgao,
                                         pCdVinculo            => rec.cdvinculo,
                                         pCdTipoFolhaPagamento => 99,
                                         pVlBaseCalculo        => rec.vlBaseCalculoNormal                              
                                        );
     
      END IF;
      
      DBMS_OUTPUT.PUT_LINE ( rec.ordem || ' - Ref: ' || cNuAnoMes );

      FOR res IN vINSSControle.calc.FIRST .. vINSSControle.calc.LAST LOOP
       
        DBMS_OUTPUT.PUT_LINE ( '     ' || case when vINSSControle.calc(res).FlDecTerceiro = 1 then '_13' else null end 
        || ' Base Calculo: ' ||  vINSSControle.calc(res).vlBaseCalculo || ' INSS: ' || vINSSControle.calc(res).vlINSS 
           || ' Base de Acerto: ' || vINSSControle.calc(res).VlBaseAcerto || '  INSS Acerto: ' || vINSSControle.calc(res).VlINSSAcerto 

        );
         
      END LOOP;
      
      PKGPAG_INSS.PDadosAnteriores (pINSSControle         => vINSSControle,
                                    pNuAnoMes             => cNuAnoMes,
                                    pCdOrgao              => rec.cdorgao,
                                    pCdVinculo            => rec.cdvinculo,
                                    pCdTipoFolhaPagamento => rec.CdTipoFolhaPagamento,
                                    pCdTipoCalculo        => rec.cdtipocalculo,
                                    pVlBaseCalculo        => rec.vlbasecalculoSup,
                                    pVlBaseAcerto         => rec.BaseAcerto,
                                    pVlINSS               => rec.vlinss);
                                           
   END LOOP;

END;

end PKGTESTEINSS;
/
