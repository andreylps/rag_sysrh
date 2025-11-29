/*

-- apagar calculo anterior
begin
   for rec in (select cdfolhapagamento
                 from epagfolhapagamento
                where nuanomesreferencia = 202505
                  and cdtipocalculo = 1) LOOP

      PKGCMP.PLimparFolhaPagamento (rec.CdFolhaPagamento);
      
   END LOOP;
END;


-- INCLUIR AS epaghistoricoparamcalculo

BEGIN
   PKGCMP.PCriarHistParamCalculo (pFlCalculoNovo => 1);
END;

-- Reagendar proxima tarefa

begin  
   PKGCMP.PReagendarProxima (pCdTarefa => NULL);
end;


*/


/* - converter o calculo antigo que terminou no tipo calculo = 2

update epagfolhapagamento fn
   set (dtcalculo, dtcredito, deordemexecucao) = (select dtcalculo, dtcredito, deordemexecucao
                                                    from epagfolhapagamento 
                                                   where cdorgao = fn.cdorgao and cdtipofolhapagamento = fn.cdtipofolhapagamento 
                                                     and cdtipocalculo = 1 and nusequencialfolha = fn.nusequencialfolha - 100
                                                     AND NUANOMESREFERENCIA = fn.nuanomesreferencia)
 where cdtipocalculo = 2
   and nuanomesreferencia = 202505;  

update epagfolhapagamento fn
   set cdtipocalculo = 3
 where cdtipocalculo = 1 and nuanomesreferencia = 202505;

update epagfolhapagamento fn
   set cdtipocalculo = 1
 where cdtipocalculo = 2 and nuanomesreferencia = 202505;

update epagfolhapagamento fn
   set cdtipocalculo = 2
 where cdtipocalculo = 3 and nuanomesreferencia = 202505;

*/
