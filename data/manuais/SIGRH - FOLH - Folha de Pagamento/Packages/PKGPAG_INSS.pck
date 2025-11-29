create or replace package PKGPAG_INSS is

  -- Author  : VENTURA
  -- Created : 24/01/2024 14:15:29
  -- Purpose : Tratar assuntos relativos a INSS     

TYPE rINSSResult IS RECORD 
(
   VlINSS                  NUMBER(13,2),
   VlSomaAcerto            NUMBER(13,2),
   VlPercentFaixa          NUMBER,
   FlMultOrgao             INTEGER
);

TYPE rINSSAliquota IS RECORD
(    
   VlInicial               number(13,2),
   VlFinal                 number(13,2),
   VlAliquota              number(10,4),
   FlAliquotaProgressiva   CHAR(1),
   VlUtilizado             number(13,2)  
);

TYPE tINSSAliquota IS TABLE OF rInssAliquota;        

TYPE rINSSFaixa IS RECORD (
   NuAnoMesIni             INTEGER,
   NuAnoMesFim             INTEGER,
   VlTeto                  NUMBER(13,2),
   VlAliqIndiv             NUMBER(4,2),
   FlAliqProgressiva       CHAR(1),
   aliquota                tINSSAliquota
   
);
    
TYPE tINSSFaixa IS TABLE OF rINSSFaixa INDEX BY PLS_INTEGER;          

TYPE rINSSFaixaCalc IS RECORD 
(
   faixa                    rINSSFaixa,
   vlSomaAcerto             NUMBER (13,2),
   vlTributado              NUMBER (13,2),
   flMultOrgao              INTEGER
);

TYPE rINSSCalculo IS RECORD (
   FlDecTerceiro            INTEGER,
   NuAnoMes                 INTEGER,
   NuCNPJOrgao              VARCHAR2(14),
   CdOrgao                  INTEGER,
   CdVinculo                INTEGER,
   CdTipoFolhaPagamento     INTEGER,
   CdTipoCalculo            INTEGER,
   VlALiquotaContribIndiv   NUMBER,   
   VlBaseCalculo            NUMBER (13,2),
   VlINSS                   NUMBER (13,2),
   VlBaseAcerto             NUMBER (13,2),
   VlINSSAcerto             NUMBER (13,2),
   VlDif                    NUMBER (13,2),
   DeDescricao              VARCHAR2(100),
   NuPercentFaixa           NUMBER

);
    
TYPE tINSSCalculo IS TABLE OF rINSSCalculo;        
         
TYPE rINSSTipoAnoMes IS RECORD (
   calc                    rINSSCalculo,
   anterior                tINSSCalculo,
   FlMultOrgao             INTEGER
);   

TYPE tINSSTipoAnoMes IS table of rINSSTipoAnoMes
   INDEX BY PLS_INTEGER; 

TYPE rINSSControle IS RECORD
(
   faixa                   tINSSFaixa,
   tipoAnoMes              tINSSTipoAnoMes   
); 
  
FUNCTION FInicializarControle RETURN rINSSControle;

PROCEDURE PNovaPessoa (pINSSControle IN OUT NOCOPY rINSSControle);

PROCEDURE PCalcular (pINSSControle           IN OUT NOCOPY rINSSControle, 
                     pNuAnoMes               IN INTEGER,
                     pFlDecTerceiro          IN INTEGER,
                     pCdOrgao                IN INTEGER,
                     pCdVinculo              IN INTEGER,  
                     pCdTipoFolhaPagamento   IN INTEGER, 
                     pCdTipoCalculo          IN INTEGER,                     
                     pVlBaseCalculo          IN INTEGER,
                     pVlAliquotaContribIndiv IN NUMBER DEFAULT NULL);

FUNCTION FCalcular (pINSSControle           IN OUT NOCOPY rINSSControle, 
                    pNuAnoMes               IN INTEGER,
                    pFlDecTerceiro          IN INTEGER,
                    pCdOrgao                IN INTEGER,
                    pCdVinculo              IN INTEGER,  
                    pCdTipoFolhaPagamento   IN INTEGER, 
                    pCdTipoCalculo          IN INTEGER,                         
                    pVlBaseCalculo          IN INTEGER,
                    pVlAliquotaContribIndiv IN NUMBER DEFAULT NULL) RETURN rINSSCalculo;
                    
FUNCTION FINSSCalculo (pINSSControle  IN rINSSControle, 
                       pFlDecTerceiro IN INTEGER, 
                       pNuAnoMes      IN INTEGER) RETURN rINSSCalculo;
 
FUNCTION FINSSCalculoAnteriores (pINSSControle  IN rINSSControle, 
                                 pFlDecTerceiro IN INTEGER, 
                                 pNuAnoMes      IN INTEGER) RETURN tINSSCalculo;
                                                                                   
PROCEDURE PDadosAnteriores (pINSSControle           IN OUT NOCOPY rINSSControle, 
                            pNuAnoMes               IN INTEGER,
                            pFlDecTerceiro          IN INTEGER,
                            pNuCnpjOrgao            IN VARCHAR2,
                            pCdOrgao                IN INTEGER,
                            pCdVinculo              IN INTEGER,
                            pCdTipoFolhaPagamento   IN INTEGER,
                            pCdTipoCalculo          IN INTEGER,
                            pVlBaseCalculo          IN INTEGER, 
                            pVlINSS                 IN NUMBER, 
                            pVlBaseAcerto           IN NUMBER DEFAULT 0,
                            pVlINSSAcerto           IN NUMBER DEFAULT 0,
                            pVlAliquotaContribIndiv IN NUMBER DEFAULT NULL,
                            pDescricao              IN VARCHAR2 DEFAULT NULL);
                                                              
end PKGPAG_INSS;
/
create or replace package body PKGPAG_INSS is

CCAL_NORMAL       CONSTANT INTEGER := 1;
CCAL_RECALCULO    CONSTANT INTEGER := 3;
CCAL_SUPLEMENTAR  CONSTANT INTEGER := 5;

-- Ordem de cálculo


CORD_EMPREG       CONSTANT INTEGER := 1;
CORD_INDIV11      CONSTANT INTEGER := 2;
CORD_INDIV20      CONSTANT INTEGER := 3;

TYPE rINSSVal IS RECORD (
   VlBaseTotal          NUMBER,
   VlDescAnteriores     NUMBER,
   VlDescCalculado      NUMBER,
   NuPercentFaixaCalc   NUMBER
);

TYPE tINSSVal IS TABLE OF rINSSVal 
 INDEX BY PLS_INTEGER; 
 
TYPE rINSSOrgao IS RECORD (
   ant                  tINSSVal,
   calc                 tINSSVal
);

TYPE tINSSOrgao IS TABLE OF rINSSOrgao;

  

PROCEDURE PDebug (pMsg IN VARCHAR2) IS
   vvalor   varchar2(32000);
BEGIN
        
   DBMS_OUTPUT.PUT_LINE ('INSS: ' || pMsg );  
   DBMS_OUTPUT.PUT_LINE ('---------------------------------------------------------------------'); 

END;

FUNCTION FChaveTipoAnoMes (pFlDecTerceiro IN INTEGER, pNuAnoMes IN INTEGER) RETURN INTEGER IS
BEGIN
   RETURN pNuAnoMes * 10 + pFlDecTerceiro;  
END;

FUNCTION FTipoAnoMesVazio RETURN rINSSTipoAnoMes IS
   vINSSTipoAnoMes  rINSSTipoAnoMes;
BEGIN
   vINSSTipoAnoMes.calc        := NULL;
   vINSSTipoAnoMes.anterior    := tINSSCalculo();
   vINSSTipoAnoMes.FlMultOrgao := 0;
   RETURN vINSSTipoAnoMes;
END;

FUNCTION FINSSCalculoAnteriores (pINSSControle  IN rINSSControle, 
                                 pFlDecTerceiro IN INTEGER, 
                                 pNuAnoMes      IN INTEGER) RETURN tINSSCalculo IS
   
   vChaveTipoAnoMes   INTEGER;
   
BEGIN
   vChaveTipoAnoMes  := FChaveTipoAnoMes (pFlDecTerceiro => pFlDecTerceiro, pNuAnoMes => pNuAnoMes);

   IF NOT pINSSControle.TipoAnoMes.EXISTS (vChaveTipoAnoMes) THEN
      RETURN NULL;
   ELSE 
      RETURN pINSSControle.TipoAnoMes(vChaveTipoAnoMes).anterior;
   END IF;   
  
END;

FUNCTION FINSSCalculo (pINSSControle  IN rINSSControle, 
                       pFlDecTerceiro IN INTEGER, 
                       pNuAnoMes      IN INTEGER) RETURN rINSSCalculo IS
   
   vChaveTipoAnoMes   INTEGER;
   
BEGIN
   vChaveTipoAnoMes  := FChaveTipoAnoMes (pFlDecTerceiro => pFlDecTerceiro, pNuAnoMes => pNuAnoMes);

   IF NOT pINSSControle.TipoAnoMes.EXISTS (vChaveTipoAnoMes) THEN
      RETURN NULL;
   ELSE 
      RETURN pINSSControle.TipoAnoMes(vChaveTipoAnoMes).calc;
   END IF;   
  
END;


FUNCTION FArmazenarFaixaINSS RETURN tINSSFaixa IS

   CURSOR cFaixa IS
   SELECT hai.NuAnoInicio * 100 + hai.NuMesInicio as NuAnoMesIni,
          NVL(hai.NuAnoFinal  * 100 + hai.NuMesFinal,999999) as NuAnoMesFim,
          F.VlInicial,
          F.VlFinal,
          F.VlAliquota,
          F.FlAliquotaProgressiva,
          hai.vlAliqContribIndividual, 
          row_number() over (PARTITION By hai.NuAnoInicio, hai.NuMesInicio ORDER BY F.VlInicial DESC) As FlUltAliquota
     FROM EtrbaliquotafaixaINSS F
    INNER JOIN etrbhistaliquotainss hai
       ON hai.cdhistaliquotainss = f.cdhistaliquotainss
    ORDER BY 1,2,3;

   vINSSAliquota     rINSSAliquota;
   vINSSTabAliquota  tINSSAliquota;
   vINSSTabFaixa     tINSSFaixa; 
   vINSSFaixa        rINSSFaixa;
   
BEGIN
 
   vINSSTabFaixa.DELETE;

   vINSSTabAliquota := tINSSAliquota();

   FOR rec IN cFaixa LOOP

      vINSSAliquota.VlInicial              := rec.VlInicial;
      vINSSAliquota.VlFinal                := rec.VlFinal;
      vINSSAliquota.VlAliquota             := rec.VlAliquota;
      vINSSAliquota.FlAliquotaProgressiva  := rec.FlAliquotaProgressiva;
      vINSSAliquota.VlUtilizado            := 0;
      
      vINSSTabAliquota.EXTEND;
      vINSSTabAliquota(vINSSTabAliquota.LAST) := vINSSAliquota;
      
      IF rec.FlUltAliquota = 1 THEN

         vINSSFaixa.NuAnoMesFim       := rec.NuAnoMesFim;
         vINSSFaixa.NuAnoMesIni       := rec.NuAnoMesIni;              
         vINSSFaixa.VlTeto            := rec.VlFinal;
         vINSSFaixa.VlAliqIndiv       := rec.vlAliqContribIndividual;
         vINSSFaixa.FlAliqProgressiva := rec.FlAliquotaProgressiva;
         vINSSFaixa.Aliquota          := vINSSTabAliquota;   
     
         vINSSTabFaixa (rec.nuanomesfim) := vINSSFaixa; 
         
         vINSSTabAliquota      := tINSSAliquota();
         
      END IF;        
   END LOOP;
                
   RETURN vINSSTabFaixa;
   
END;

FUNCTION FInicializarControle RETURN rINSSControle IS
   vINSSControle     rINSSControle;   
BEGIN
   vINSSControle       := NULL;
   vINSSControle.faixa := FArmazenarFaixaINSS;
   vINSSControle.tipoAnoMes.delete;
      
   RETURN vINSSControle;
END;

PROCEDURE PNovaPessoa (pINSSControle IN OUT NOCOPY rINSSControle) IS 
BEGIN
   pINSSControle.tipoAnoMes.delete;
END;

FUNCTION FRetornarFaixaINSS (pINSSControle IN rINSSControle, pNuAnoMes IN INTEGER) RETURN rINSSFaixa IS
 
   vFaixa     rINSSFaixa;
   vInd       INTEGER;
BEGIN
 
   vFaixa := NULL;
 
   vInd := pINSSControle.faixa.NEXT (pNuAnoMes - 1);
   
   IF vInd IS NOT NULL THEN
      vFaixa := pINSSControle.faixa(vInd);
   END IF;
   
   RETURN vFaixa;
   
END;

PROCEDURE PCalcularINSSOrgaos (pINSSControle     IN rINSSControle,  
                               pNuAnoMes         IN INTEGER,
                               pINSSOrgao    IN OUT NOCOPY tINSSOrgao) IS
   

   vFaixa             rINSSFaixa;  
 
   vVlINSS1           NUMBER;
   vVlINSS2           NUMBER;

   vNuPercentFaixa    NUMBER;
   vVlSaldoTeto       NUMBER; 
   vAliquota          rINSSAliquota;
       
   PROCEDURE PImprimir IS
      
   BEGIN
        
      FOR aliq IN vFaixa.aliquota.FIRST .. vFaixa.aliquota.LAST LOOP  
         
         vAliquota := vFaixa.aliquota(aliq);
                  
         dbms_output.put_line ('Faixa ' || aliq || ' (' || vAliquota.vlInicial || 
         '-' || vAliquota.vlFinal || ') Utilizado = ' || vAliquota.vlUtilizado);
 
      END LOOP;
    
   END;
 
/*  
   PROCEDURE PAcumularTabOrdemAcerto IS
      
      vOrdem           rINSSOrgao; 
      vInd             INTEGER;
      vFlAcum          BOOLEAN;
      vCdOrgaoCNPJ     VARCHAR2(14);
      TYPE tIntIndex IS TABLE OF PLS_INTEGER INDEX BY VARCHAR2(14);
      vTabCdOrgaoCNPJ  tIntIndex;  
      
   BEGIN
      vTabCdOrgaoCNPJ.DELETE;
      vTabOrdem := tINSSOrgao();
      vFlAcum   := TRUE;
      
      FOR rec IN pINSSControle.tipoAnoMes(pChaveTipoAnoMes).anterior.FIRST .. pINSSControle.tipoAnoMes(pChaveTipoAnoMes).anterior.LAST LOOP
         
         vOrdem := pINSSControle.tipoAnoMes(pChaveTipoAnoMes).anterior(rec);
                
         IF pINSSCalculo.CdOrgao = vOrdem.cdOrgao THEN -- é do orgao que estou calculando, pára de acumular orgaos novos
            vINSSFaixaCalc.VlSomaAcerto := vINSSFaixaCalc.VlSomaAcerto + vOrdem.VlBaseAcerto;
            vFlAcum := FALSE;
         ELSE
            
            vCdOrgaoCNPJ := NVL(vOrdem.cdOrgao, vORdem.NuCNPJOrgao);         
            
            IF NOT vTabCdOrgaoCNPJ.EXISTS (vCdOrgaoCNPJ) THEN
               IF vFlAcum THEN 
                  vTabOrdem.EXTEND;
                  vInd := vTabOrdem.LAST;
                  vTabCdOrgaoCNPJ (vCdOrgaoCNPJ) := vInd;
                  vTabOrdem(vInd) := vOrdem;
               END IF;
            ELSE
               -- somar no sequencial que já existia
               vInd := vTabCdOrgaoCNPJ (vCdOrgaoCNPJ);
               vTabOrdem(vInd).vlBaseCalculo := vTabOrdem(vInd).vlBaseCalculo + vOrdem.VlBaseCalculo; 
            END IF;
         END IF;
      END LOOP;       
              
   END;
*/
    
   PROCEDURE PCalcINSSVal (pTrib IN INTEGER, pVlBase1 IN NUMBER  DEFAULT 0, pVlBase2 IN NUMBER) IS

      vVlPercentIndiv    NUMBER;
      vVlATributar1      NUMBER;
      vVlATributar2      NUMBER;

      vVlTribFaixa1      NUMBER;
      vVlTribFaixa2      NUMBER;
            
      vVlDisponivel      NUMBER;  
                  
   BEGIN
         
      IF pVlBase1 > vVlSaldoTeto THEN
         vVlATributar1 := vVlSaldoTeto;
         vVlATributar2 := vVlSaldoTeto;
         vVlSaldoTeto  := 0;
      ELSE
         vVlATributar1 := pVlBase1;
         IF (pVlBase1 + pVlBase2) > vVlSaldoTeto THEN
            vVlATributar2 := vVlSaldoTeto;
            vVlSaldoTeto  := 0;
         ELSE
            vVlATributar2 := pVlBase1 + pVlBase2;
            vVlSaldoTeto  := vVlSaldoTeto - vVlATributar2;
         END IF;         
      END IF;
                       
      vVlINSS1      := 0;
      vVlINSS2      := 0;
       
      IF pTrib <> CORD_EMPREG THEN 
            
         IF pTrib = CORD_INDIV11 THEN
            vVlPercentIndiv := 11;
         ELSE
            vVlPercentIndiv := 20;
         END IF;            
        
         vVlINSS1 := trunc(vVlATributar1 * vVlPercentIndiv / 100,2);
         vVlINSS2 := trunc(vVlATributar2 * vVlPercentIndiv / 100,2);
         vNuPercentFaixa := vVlPercentIndiv;          
         
      ELSE        
  
         FOR aliq IN vFaixa.aliquota.FIRST .. vFaixa.aliquota.LAST LOOP  
               
            vAliquota := vFaixa.aliquota(aliq);
                
            vVlDisponivel := valiquota.VlFinal - valiquota.VlInicial + 0.01 - valiquota.VlUtilizado;
               
            IF vVlDisponivel = 0 THEN
               CONTINUE;
            END IF;
            
            -- utilizar o valor da faixa

            IF vVlATributar1 <= vVlDisponivel THEN
               vVlTribFaixa1 := vVlATributar1;
            ELSE
               vVlTribFaixa1 := vVlDisponivel;
            END IF;
                         
            IF vVlATributar2 <= vVlDisponivel THEN
               vVlTribFaixa2 := vVlATributar2;
            ELSE
               vVlTribFaixa2 := vVlDisponivel;
            END IF;
                             
            vAliquota.VlUtilizado := vAliquota.VlUtilizado + vVlTribFaixa2;
            
            vVlATributar1 := vVlATributar1 - vVlTribFaixa1;
            vVlATributar2 := vVlATributar2 - vVlTribFaixa2;           
               
            -- Calcular o INSS
               
            vVlINSS1 := vVlINSS1 + trunc( (vVlTribFaixa1 * vAliquota.VlAliquota)/100,2); 
            vVlINSS2 := vVlINSS2 + trunc( (vVlTribFaixa2 * vAliquota.VlAliquota)/100,2);
          
            vNuPercentFaixa := vAliquota.VlAliquota;
               
            -- Atualizar a faixa
               
            vFaixa.aliquota(aliq) := vAliquota;
               
            -- Testar saida
               
            IF vVlATributar1 = 0 AND vVlATributar2 = 0 THEN -- Nada mais a tributar
               EXIT;
            END IF;
               
         END LOOP;
   
      END IF;
             
   END;

BEGIN
   
   vFaixa := FRetornarFaixaINSS (pINSSControle => pINSSControle, pNuAnoMes => pNuAnoMes);

   vVlSaldoTeto := vFaixa.VlTeto;

   FOR i in pINSSOrgao.FIRST .. pINSSOrgao.LAST LOOP
         
      IF vVlSaldoTeto = 0 THEN
         EXIT;
      END IF;

      FOR t IN 1 .. 3 LOOP
   
         IF pINSSOrgao(i).ant.EXISTS (t) AND pINSSOrgao(i).calc.EXISTS (t) THEN
              
            PCalcINSSVal (pTrib => t, pVlBase1 => pINSSOrgao(i).ant(t).VlBaseTotal, pVlBase2 => pINSSOrgao(i).calc(t).VlBaseTotal);
         
            pINSSOrgao(i).ant(t).VlDescCalculado      := vVlINSS1;
            pINSSOrgao(i).calc(t).VlDescCalculado     := vVlINSS2;     
            pINSSOrgao(i).calc(t).NuPercentFaixaCalc  := vNuPercentFaixa;        
         
         ELSIF pINSSOrgao(i).calc.EXISTS (t) THEN

            PCalcINSSVal (pTrib => t, pVlBase2 => pINSSOrgao(i).calc(t).VlBaseTotal);
                        
            pINSSOrgao(i).calc(t).VlDescCalculado     := vVlINSS2; 
            pINSSOrgao(i).calc(t).NuPercentFaixaCalc  := vNuPercentFaixa;         

         ELSIF pINSSOrgao(i).ant.EXISTS (t) THEN

            PCalcINSSVal (pTrib => t, pVlBase2 => pINSSOrgao(i).ant(t).VlBaseTotal);

            pINSSOrgao(i).ant(t).VlDescCalculado      := vVlINSS2;            
         END IF;  
                              
      END LOOP;
        
   END LOOP;

END;

FUNCTION FCalcularINSS (pINSSCalculo IN rINSSCalculo, pINSSFaixaCalc IN OUT NOCOPY rINSSFaixaCalc) RETURN rINSSResult IS

   vValorTributar    NUMBER;
   vValorFaixa       NUMBER;
   vINSSResult       rINSSResult;
   
BEGIN
   
   vINSSResult.VlINSS         := 0;   
   vINSSResult.VlSomaAcerto   := pINSSFaixaCalc.vlSomaAcerto;
   vINSSResult.FlMultOrgao    := pINSSFaixaCalc.FlMultOrgao;
   VINSSResult.VlPercentFaixa := 0;
   
   IF pINSSFaixaCalc.VlTributado < pINSSFaixaCalc.faixa.VlTeto THEN

      vValorTributar := least (pINSSFaixaCalc.faixa.VlTeto , pINSSCalculo.VlBaseCalculo + pINSSFaixaCalc.VlTributado);   
      
      vValorTributar := vValorTributar - pINSSFaixaCalc.VlTributado;
       
      IF pINSSCalculo.VlAliquotaContribIndiv > 0 THEN -- Calculo de percentual individual   

         vINSSResult.VlINSS := trunc(vValorTributar * pINSSCalculo.VlAliquotaContribIndiv / 100,2);
         VINSSResult.VlPercentFaixa := pINSSCalculo.VlAliquotaContribIndiv;
          
      ELSE
         
         FOR i IN pINSSFaixaCalc.faixa.aliquota.FIRST .. pINSSFaixaCalc.faixa.aliquota.LAST LOOP
          
            vValorFaixa := (pINSSFaixaCalc.faixa.aliquota(i).VlFinal - pINSSFaixaCalc.faixa.aliquota(i).VlInicial + 0.01) - pINSSFaixaCalc.faixa.aliquota(i).VlUtilizado;

            IF vValorTributar < vValorFaixa then
               vValorFaixa := vValorTributar;
            END IF;
            
            vINSSResult.VlINSS := vINSSResult.VlINSS + trunc( (vValorFaixa * pINSSFaixaCalc.faixa.aliquota(i).VlAliquota)/100,2); 
            
            vValorTributar := vValorTributar - vValorFaixa;
            
            IF vValorTributar = 0 THEN
               VINSSResult.VlPercentFaixa := pINSSFaixaCalc.faixa.aliquota(i).VlAliquota;
               EXIT;
            END IF;
           
         END LOOP;

      END IF;
   
   ELSE
      
      IF pINSSCalculo.VlAliquotaContribIndiv > 0 THEN
         VINSSResult.VlPercentFaixa := pINSSCalculo.VlAliquotaContribIndiv;
      ELSE
      
         VINSSResult.VlPercentFaixa := pINSSFaixaCalc.faixa.aliquota(pINSSFaixaCalc.faixa.aliquota.LAST).VlAliquota;
      END IF;
      
   END IF;
     
   RETURN vINSSResult;
   
END;

FUNCTION FCalcularBaseINSS (pINSSControle IN rINSSControle, pINSSCalculo IN rINSSCalculo, pINSSFaixaCalc IN OUT rINSSFaixaCalc) RETURN NUMBER IS

   vINSSCalculo      rINSSCalculo;
   vVlBaseMin        NUMBER;
   vVlBaseMax        NUMBER;
   vVlINSSProcurado  NUMBER;
   vINSSResult       rINSSResult;
  
BEGIN

   IF pINSSCalculo.VlINSSAcerto > 0 THEN -- Aumentar a base
      vVlBaseMin := pINSSCalculo.VlBaseCalculo;
      vVlBaseMax := pINSSControle.faixa(pINSSControle.faixa.LAST).VlTeto;
   ELSE
      vVlBaseMin := 0;
      vVlBaseMax := pINSSCalculo.VlBaseCalculo;      
   END IF;

   vVlINSSProcurado := pINSSCalculo.VlINSS;

   vINSSCalculo    := pINSSCalculo;
     
   WHILE TRUE LOOP
 
      IF vVlBaseMax - vVlBaseMin = 0.01 THEN
         vVlBaseMin := vVlBaseMax;
      END IF;

      vINSSCalculo.VlBaseCalculo := trunc( (vVlBaseMin + vVlBaseMax) / 2,2);
  
      vINSSResult := FCalcularINSS (pINSSCalculo => pINSSCalculo, pINSSFaixaCalc => pINSSFaixaCalc);
 
      IF vINSSResult.VlINSS = vVlINSSProcurado THEN
         EXIT;
      ELSE 
         IF vVlBaseMin = vVlBaseMax THEN -- desistir
            vINSSCalculo.VlBaseCalculo := NULL;
            EXIT;             
         ELSIF vINSSResult.VlINSS < vVlINSSProcurado THEN
            vVlBaseMin := vINSSCalculo.VlBaseCalculo;
         ELSE
            vVlBaseMax := vINSSCalculo.VlBaseCalculo;
         END IF;
      END IF;

   END LOOP;  
  
  -- DBMS_OUTPUT.PUT_LINE ('Base de acerto para inss ' || vINSSCalculo.vlinss || ' = ' || vINSSCalculo.VlBaseCalculo
  -- || ' ja de acerto ' || pINSSFaixaCalc.vlSomaAcerto
  -- );
 
   RETURN vINSSCalculo.VlBaseCalculo;
 
END;

/*
PROCEDURE PCalcularAcerto (pINSSControle IN OUT NOCOPY rINSSControle, pChaveTipoAnoMes IN INTEGER, pINSSCalculo IN rINSSCalculo ,pBaseAcerto OUT NUMBER, pINSSACerto OUT NUMBER) IS

   vINSSCalcAcerto     rINSSCalculo;
   vINSSResult        rINSSResult;
   vINSSFaixaCalc  rINSSFaixaCalc;
BEGIN
     
   -- Calcular INSS da base total da pessoa
   vINSSCalcAcerto := pINSSCalculo;

   vINSSFaixaCalc  := FObterFaixaTratada (pINSSControle    => pINSSControle, 
                                          pChaveTipoAnoMes => pChaveTipoAnoMes,
                                          pINSSCalculo     => vINSSCalcAcerto,
                                          pINSSOrgao       => tINSSOrgao(), 
                                          pLimiteOrg       => 0,
                                          pFlAcerto        => 1);

   vINSSResult := FCalcularINSS (pINSSCalculo => vINSSCalcAcerto, pINSSFaixaCalc => vINSSFaixaCalc);

   vINSSCalcAcerto.vlINSSAcerto := 0;    
   vINSSCalcAcerto.VlBaseAcerto := 0;
   
   IF vINSSResult.vlINSS <> pINSSCalculo.VlINSS THEN
      vINSSCalcAcerto.VlINSSAcerto := pINSSCalculo.VlINSS - vINSSResult.vlINSS;
      vINSSCalcAcerto.VlINSS       := pINSSCalculo.VlINSS; 
      vINSSCalcAcerto.VlBaseAcerto := FCalcularBaseINSS (pINSSControle => pINSSControle, pINSSCalculo => vINSSCalcAcerto, pINSSFaixaCalc => vINSSFaixaCalc);
           
      vINSSCalcAcerto.VlBaseAcerto := vINSSCalcAcerto.VlBaseAcerto - pINSSCalculo.VlBaseCalculo
                                      - vINSSFaixaCalc.vlSomaAcerto;
      
      
   END IF;
 
   pBaseAcerto := vINSSCalcAcerto.VlBaseAcerto;
   pINSSACerto := vINSSCalcAcerto.vlINSSAcerto;
 
END;
*/

PROCEDURE PAcumularCalculo  (pINSSOrgao        IN tINSSOrgao,
                             pVlDescAtual     OUT NUMBER,
                             pNuPercentFaixa  OUT NUMBER, 
                             pVlDescDif       OUT NUMBER                             
                             ) IS

   vVlDescAnterior   NUMBER;
   vVlDescDevido     NUMBER;
      
  
BEGIN
   pVlDescAtual      := 0;
   
   vVlDescAnterior   := 0;
   vVlDescDevido     := 0;
    
   FOR i in pINSSOrgao.FIRST .. pINSSOrgao.LAST LOOP
      
      FOR t IN 1 .. 3 LOOP
      
         IF pINSSOrgao(i).calc.EXISTS (t) THEN
            
            pVlDescAtual    := pVlDescAtual + pINSSOrgao(i).calc(t).VlDescCalculado;
         
            IF pINSSOrgao(i).ant.EXISTS (t) THEN           
               pVlDescAtual := pVlDescAtual - pINSSOrgao(i).ant(t).VlDescCalculado;
            END IF;

            pNuPercentFaixa := pINSSOrgao(i).calc(t).NuPercentFaixaCalc;
         END IF;
         
         IF pINSSOrgao(i).ant.EXISTS (t) THEN
                    
            vVlDescAnterior := vVlDescAnterior + pINSSOrgao(i).ant(t).VlDescAnteriores;
            vVlDescDevido   := vVlDescDevido   + pINSSOrgao(i).ant(t).VlDescCalculado;
         END IF;  
            
      END LOOP;
      
   END LOOP;
 
   pVlDescDif   := vVlDescDevido - vVlDescAnterior;
   
   pVlDescAtual := pVlDescAtual + pVlDescDif;
       
END;

PROCEDURE PCalcularINSSTipoAnoMes (pINSSControle           IN rINSSControle, 
                                   pINSSCalculoCalc    IN OUT NOCOPY rINSSCalculo,
                                   pNuAnoMes               IN INTEGER,
                                   pChaveTipoAnoMes        IN INTEGER) IS
  
   vINSSCalculoAnt     rINSSCalculo;
   vTrib               INTEGER;
   
   TYPE tLstOrgao IS TABLE OF PLS_INTEGER INDEX BY VARCHAR2(14);   

   vOrg                INTEGER;
   vFlFolhaAceitar     BOOLEAN;
   
   vTabINSSOrgao       tINSSOrgao;
   vTabLstOrgao        tLstOrgao;
   
   vChaveOrgaoAnt      VARCHAR2(14);
   vChaveOrgaoCalc     VARCHAR2(14);
   
   FUNCTION FChaveOrgao (pCdOrgao IN INTEGER, pNuCNPJOrgao IN VARCHAR2) RETURN VARCHAR2 IS      
   BEGIN
      IF pCdOrgao IS NOT NULL THEN
         RETURN 'ORG' || pCdOrgao;
      ELSE
         RETURN pNuCNPJOrgao;
      END IF; 
   END;
   
   PROCEDURE PSomarValores (pTrib IN INTEGER, pFlAnt IN INTEGER, pVlBase IN NUMBER, pVlDesc IN NUMBER)  IS

   BEGIN
      IF pFlAnt = 1 THEN
         IF NOT vTabINSSOrgao(vOrg).ant.EXISTS (pTrib) THEN
            vTabINSSOrgao(vOrg).ant(pTrib) := rINSSVal (VlBaseTotal => 0, VlDescAnteriores => 0, VlDescCalculado => 0, NuPercentFaixaCalc => 0);             
         END IF;   

         vTabINSSOrgao(vOrg).ant(pTrib).VlBaseTotal        := vTabINSSOrgao(vOrg).ant(pTrib).VlBaseTotal      + pVlBase;
         vTabINSSOrgao(vOrg).ant(pTrib).VlDescAnteriores   := vTabINSSOrgao(vOrg).ant(pTrib).VlDescAnteriores + pVlDesc;
         vTabINSSOrgao(vOrg).ant(pTrib).VlDescCalculado    := 0;
         vTabINSSOrgao(vOrg).ant(pTrib).NuPercentFaixaCalc := 0;   
               
      ELSE
         
         IF NOT vTabINSSOrgao(vOrg).calc.EXISTS (pTrib) THEN
            vTabINSSOrgao(vOrg).calc(pTrib) := rINSSVal (VlBaseTotal => 0, VlDescAnteriores => 0, VlDescCalculado => 0, NuPercentFaixaCalc => 0);             
         END IF;   

         vTabINSSOrgao(vOrg).calc(pTrib).VlBaseTotal        := vTabINSSOrgao(vOrg).calc(pTrib).VlBaseTotal      + pVlBase;
         vTabINSSOrgao(vOrg).calc(pTrib).VlDescAnteriores   := vTabINSSOrgao(vOrg).calc(pTrib).VlDescAnteriores + pVlDesc;
         vTabINSSOrgao(vOrg).calc(pTrib).VlDescCalculado    := 0;
         vTabINSSOrgao(vOrg).calc(pTrib).NuPercentFaixaCalc := 0;   
         
      END IF;
      
   END;
 
BEGIN
            
   vTabLstOrgao.DELETE;
   vTabINSSOrgao := tINSSOrgao();   
   
   vChaveOrgaoCalc  := FChaveOrgao (pCdOrgao => pINSSCalculoCalc.CdOrgao, pNuCNPJOrgao => pINSSCalculoCalc.NuCNPJOrgao);      

   -- Percorrer e acumular os impostos por orgao de calculos anteriores
   
   IF pINSSControle.TipoAnoMes(pChaveTipoAnoMes).anterior.COUNT > 0 THEN
      
      FOR ant IN pINSSControle.TipoAnoMes(pChaveTipoAnoMes).anterior.FIRST .. pINSSControle.TipoAnoMes(pChaveTipoAnoMes).anterior.LAST LOOP
         
         vINSSCalculoAnt := pINSSControle.TipoAnoMes(pChaveTipoAnoMes).anterior(ant);
         
         vChaveOrgaoAnt  := FChaveOrgao (pCdOrgao => vINSSCalculoAnt.CdOrgao, pNuCNPJOrgao => vINSSCalculoAnt.NuCNPJOrgao);      

         IF NOT vTabLstOrgao.EXISTS (vChaveOrgaoAnt) THEN
            vTabINSSOrgao.EXTEND;
            vOrg := vTabINSSOrgao.LAST;

            vTabLstOrgao  (vChaveOrgaoAnt) := vOrg;
            vTabINSSOrgao (vOrg) := NULL;
            vTabINSSOrgao (vOrg).ant.DELETE;
            vTabINSSOrgao (vOrg).calc.DELETE;
                        
         ELSE
            vOrg := vTabLstOrgao (vChaveOrgaoAnt);  
         END IF;
         
         vFlFolhaAceitar := TRUE;
         
         IF pINSSCalculoCalc.CdTipoCalculo = CCAL_RECALCULO
            AND vChaveOrgaoAnt = vChaveOrgaoCalc
            AND vINSSCalculoAnt.CdVinculo = pINSSCalculoCalc.CdVinculo 
            AND vINSSCalculoAnt.CdTipoFolhaPagamento = pINSSCalculoCalc.CdTipoFolhaPagamento THEN
            vFlFolhaAceitar := FALSE;
         END IF;

         IF vFlFolhaAceitar THEN        
          
            IF vINSSCalculoAnt.VlALiquotaContribIndiv IS NULL THEN
               vTrib := CORD_EMPREG;
            ELSIF vINSSCalculoAnt.VlALiquotaContribIndiv = 11 THEN
               vTrib := CORD_INDIV11;
            ELSIF vINSSCalculoAnt.VlALiquotaContribIndiv = 20 THEN      
               vTrib := CORD_INDIV20;
            ELSE
               raise_application_error( -20001, 'INSS: Contribuinte individual anterior permite somente 11% ou 20%');
            END IF;
                       
            PSomarValores (pTrib   => vTrib,
                           pFlAnt  => 1,
                           pVlBase => vINSSCalculoAnt.VlBaseCalculo, 
                           pVlDesc => vINSSCalculoAnt.VlINSS);
         END IF;
              
            
      END LOOP;
      
   END IF;
   
   -- Tratando calculo atual
     
   -- Verificar se o calculo atual já tem ordem definida
  
   IF pINSSCalculoCalc.VlALiquotaContribIndiv IS NULL THEN
      vTrib := CORD_EMPREG;
   ELSIF pINSSCalculoCalc.VlALiquotaContribIndiv = 11 THEN
      vTrib := CORD_INDIV11;
   ELSIF pINSSCalculoCalc.VlALiquotaContribIndiv = 20 THEN      
      vTrib := CORD_INDIV20;
   ELSE
      raise_application_error( -20001, 'INSS: Contribuinte individual permite somente 11% ou 20%');
   END IF;

   IF NOT vTabLstOrgao.EXISTS (vChaveOrgaoCalc) THEN

      vTabINSSOrgao.EXTEND;
      vOrg := vTabINSSOrgao.LAST;
           
      vTabLstOrgao (vChaveOrgaoCalc) := vOrg;
      
      vTabINSSOrgao (vOrg) := NULL;
      vTabINSSOrgao (vOrg).ant.DELETE;
      vTabINSSOrgao (vOrg).calc.DELETE;

   ELSE
       vOrg := vTabLstOrgao (vChaveOrgaoCalc);
   END IF;
      
   PSomarValores (pTrib   => vTrib,
                  pFlAnt  => 0,
                  pVlBase => pINSSCalculoCalc.VlBaseCalculo, 
                  pVlDesc => 0);             
       
   -- Fazer o cálculo

   PCalcularINSSOrgaos (pINSSControle     => pINSSControle, 
                        pNuAnoMes         => pNuAnoMes,
                        pINSSOrgao        => vTabINSSOrgao);
    
   -- Obter os valores da tributacao
   
   PAcumularCalculo  (pINSSOrgao       => vTabINSSOrgao,
                      pVlDescAtual     => pINSSCalculoCalc.vlINSS,
                      pNuPercentFaixa  => pINSSCalculoCalc.NuPercentFaixa,
                      pVlDescDif       => pINSSCalculoCalc.vlDif                       
                      );
   
END;
                       
FUNCTION FCalcular (pINSSControle           IN OUT NOCOPY rINSSControle, 
                    pNuAnoMes               IN INTEGER,
                    pFlDecTerceiro          IN INTEGER,
                    pCdOrgao                IN INTEGER,
                    pCdVinculo              IN INTEGER,  
                    pCdTipoFolhaPagamento   IN INTEGER, 
                    pCdTipoCalculo          IN INTEGER,                         
                    pVlBaseCalculo          IN INTEGER,
                    pVlAliquotaContribIndiv IN NUMBER DEFAULT NULL) RETURN rINSSCalculo IS

   vINSSCalculo        rINSSCalculo;
   vChaveTipoAnoMes    INTEGER;
   
BEGIN
   
   IF pCdTipoCalculo not in (CCAL_NORMAL,CCAL_RECALCULO) THEN
      raise_application_error( -20001, 'INSS: Somente calcular Normal ou Recálculo');
   END IF;
   
   vChaveTipoAnoMes := FChaveTipoAnoMes (pFlDecTerceiro => pFlDecTerceiro, pNuAnoMes => pNuAnoMes);
   
   vINSSCalculo.NuAnoMes                := pNuAnoMes;  
   vINSSCalculo.FlDecTerceiro           := pFlDecTerceiro;
   vINSSCalculo.CdOrgao                 := pCdOrgao;
   vINSSCalculo.CdVinculo               := pCdVinculo;   
   vINSSCalculo.CdTipoFolhaPagamento    := pCdTipoFolhaPagamento;
   vINSSCalculo.CdTipoCalculo           := pCdTipoCalculo;
   vINSSCalculo.VlBaseCalculo           := NVL(pVlBaseCalculo,0);
   vINSSCalculo.VlALiquotaContribIndiv  := pVlALiquotaContribIndiv; 
   vINSSCalculo.VlBaseAcerto            := 0;
   vINSSCalculo.VlINSSAcerto            := 0;
   
   IF NOT pINSSControle.tipoAnoMes.EXISTS (vChaveTipoAnoMes) THEN
      pINSSControle.tipoAnoMes(vChaveTipoAnoMes)   := FTipoAnoMesVazio;
   END IF;   
  
   pINSSControle.tipoAnoMes(vChaveTipoAnoMes).calc := vINSSCalculo;
   
   PCalcularINSSTipoAnoMes (pINSSControle    => pINSSControle, 
                            pINSSCalculoCalc => vINSSCalculo,
                            pNuAnoMes        => pNuAnoMes,
                            pChaveTipoAnoMes => vChaveTipoAnoMes);
                             
   pINSSControle.tipoAnoMes(vChaveTipoAnoMes).calc := vINSSCalculo;

   --PDebug ('Calcular org/vinc: ' || vINSSCalculo.CdOrgao || '/' ||  vINSSCalculo.CdVinculo ||
   --        ' base/inss/indiv:' || vINSSCalculo.VlBaseCalculo || '/' || vINSSCalculo.VlINSS
   --                   || '/' || vINSSCalculo.VlAliquotaContribIndiv);      
    
   vINSSCalculo.FlDecTerceiro           := pFlDecTerceiro;
   vINSSCalculo.CdOrgao                 := pCdOrgao;
   vINSSCalculo.CdVinculo               := pCdVinculo;   
   vINSSCalculo.CdTipoFolhaPagamento    := pCdTipoFolhaPagamento;
   vINSSCalculo.CdTipoCalculo           := pCdTipoCalculo;
   vINSSCalculo.VlBaseCalculo           := NVL(pVlBaseCalculo,0);
   vINSSCalculo.VlALiquotaContribIndiv  := pVlALiquotaContribIndiv; 
   vINSSCalculo.VlBaseAcerto            := 0;
   vINSSCalculo.VlINSSAcerto            := 0;

   
                      
   RETURN vINSSCalculo;
   
END;


PROCEDURE PCalcular (pINSSControle           IN OUT NOCOPY rINSSControle, 
                     pNuAnoMes               IN INTEGER,
                     pFlDecTerceiro          IN INTEGER,
                     pCdOrgao                IN INTEGER,
                     pCdVinculo              IN INTEGER,  
                     pCdTipoFolhaPagamento   IN INTEGER, 
                     pCdTipoCalculo          IN INTEGER,                         
                     pVlBaseCalculo          IN INTEGER,
                     pVlAliquotaContribIndiv IN NUMBER DEFAULT NULL) IS

   vINSSCalculo        rINSSCalculo;                    
BEGIN
   
   vINSSCalculo := FCalcular (pINSSControle           => pINSSControle,
                              pNuAnoMes               => pNuAnoMes,
                              pFlDecTerceiro          => pFlDecTerceiro,
                              pCdOrgao                => pCdOrgao,
                              pCdVinculo              => pCdVinculo, 
                              pCdTipoFolhaPagamento   => pcdTipoFolhaPagamento,
                              pCdTipoCalculo          => pCdTipoCalculo,           
                              pVlBaseCalculo          => pVlBaseCalculo,
                              pVlAliquotaContribIndiv => pVlAliquotaContribIndiv); 
         
END;
                     

PROCEDURE PDadosAnteriores (pINSSControle           IN OUT NOCOPY rINSSControle, 
                            pNuAnoMes               IN INTEGER,
                            pFlDecTerceiro          IN INTEGER,
                            pNuCnpjOrgao            IN VARCHAR2,
                            pCdOrgao                IN INTEGER,
                            pCdVinculo              IN INTEGER,
                            pCdTipoFolhaPagamento   IN INTEGER,
                            pCdTipoCalculo          IN INTEGER,
                            pVlBaseCalculo          IN INTEGER, 
                            pVlINSS                 IN NUMBER, 
                            pVlBaseAcerto           IN NUMBER DEFAULT 0,
                            pVlINSSAcerto           IN NUMBER DEFAULT 0,
                            pVlAliquotaContribIndiv IN NUMBER DEFAULT NULL,
                            pDescricao              IN VARCHAR2 DEFAULT NULL) IS
 
   vINSSCalculo       rINSSCalculo;
   vChaveTipoAnoMes   INTEGER;
   vCdOrgaoCNPJ       VARCHAR2(14);
   vCdOrgaoCNPJAnt    VARCHAR2(14);
BEGIN  
 
   IF pCdTipoCalculo not in (CCAL_NORMAL,CCAL_SUPLEMENTAR) THEN
      raise_application_error( -20001, 'INSS: Somente aceito dados anteriores de Normal ou Suplementar');
   END IF;

   IF NOT(pVlAliquotaContribIndiv IS NULL OR pVlAliquotaContribIndiv IN (11,20) ) THEN
      raise_application_error( -20001, 'INSS: Contribuinte individual anterior permite somente 11% ou 20%');
   END IF;
                 
   vChaveTipoAnoMes := FChaveTipoAnoMes (pFlDecTerceiro => pFlDecTerceiro, pNuAnoMes => pNuAnoMes);
   
   vINSSCalculo.FlDecTerceiro          := pFlDecTerceiro;
   vINSSCalculo.NuAnoMes               := pNuAnoMes;
   vINSSCalculo.NuCNPJOrgao            := pNuCnpjOrgao;
   vINSSCalculo.CdOrgao                := pCdOrgao;
   vINSSCalculo.CdVinculo              := pCdVinculo;
   vINSSCalculo.CdTipoFolhaPagamento   := pCdTipoFolhaPagamento;
   vINSSCalculo.CdTipoCalculo          := pCdTipoCalculo;
   vINSSCalculo.VlAliquotaContribIndiv := pVlAliquotaContribIndiv;
   vINSSCalculo.VlBaseCalculo          := NVL(pVlBaseCalculo,0);
   vINSSCalculo.VlINSS                 := NVL(pVlINSS,0);    
   vINSSCalculo.VlBaseAcerto           := NVL(pVlBaseAcerto,0);                               
   vINSSCalculo.VlINSSAcerto           := NVL(pVlINSSAcerto,0); 
   vINSSCalculo.DeDescricao            := pDescricao;
   vINSSCalculo.NuPercentFaixa         := NULL;
   
   IF NOT pINSSControle.tipoAnoMes.EXISTS (vChaveTipoAnoMes) THEN
      pINSSControle.tipoAnoMes(vChaveTipoAnoMes) := FTipoAnoMesVazio;
      vCdOrgaoCNPJAnt := NULL;
   ELSIF pINSSControle.tipoAnoMes(vChaveTipoAnoMes).anterior.COUNT > 0 THEN
         
      vCdOrgaoCNPJAnt := pINSSControle.tipoAnoMes(vChaveTipoAnoMes).anterior(pINSSControle.tipoAnoMes(vChaveTipoAnoMes).anterior.LAST).CdOrgao;
      IF vCdOrgaoCNPJAnt IS NULL THEN
         vCdOrgaoCNPJAnt := pINSSControle.tipoAnoMes(vChaveTipoAnoMes).anterior(pINSSControle.tipoAnoMes(vChaveTipoAnoMes).anterior.LAST).NuCNPJOrgao;      
      END IF;
   END IF;

   pINSSControle.tipoAnoMes(vChaveTipoAnoMes).anterior.EXTEND;   
   pINSSControle.tipoAnoMes(vChaveTipoAnoMes).anterior (pINSSControle.tipoAnoMes(vChaveTipoAnoMes).anterior.LAST) := vINSSCalculo;
   
   vCdOrgaoCNPJ := vINSSCalculo.cdOrgao;
   IF vCdOrgaoCNPJ IS NULL THEN
      vCdOrgaoCNPJ := vINSSCalculo.NuCnpjOrgao;   
   END IF;
   
   IF pINSSControle.tipoAnoMes(vChaveTipoAnoMes).FlMultOrgao = 0 AND vCdOrgaoCNPJAnt IS NOT NULL AND vCdOrgaoCNPJ <> vCdOrgaoCNPJAnt THEN
      pINSSControle.tipoAnoMes(vChaveTipoAnoMes).FlMultOrgao := 1;
   END IF;
   
   --PDebug ('Calculo anterior base/inss/indiv:' || vINSSCalculo.VlBaseCalculo || '/' || vINSSCalculo.VlINSS
   --                   || '/' || vINSSCalculo.VlAliquotaContribIndiv);
 
   
END;
  
end PKGPAG_INSS;
/
