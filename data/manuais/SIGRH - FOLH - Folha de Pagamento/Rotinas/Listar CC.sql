-- select * from ecmpresumo where cdpessoa = 1237000

select cdfolhapagamento, cdvinculo, cc.* from vpagcc cc
where nuanomesreferencia = 202505
and cdpessoa = 1401032
and cdtipocalculo = 1;

declare
   pCdVinculo        integer := 1113882;
   pCdFolhaAtual     integer := 520184;
begin
   FOR rec IN (Select fd.CdFolhaPagamento, fo.CdTipoFolhaPagamento, fo.CdOrgao
                 from epagfolhapagamento fo
                inner join epagfolhapagamento fd
                   on fd.cdorgao = fo.cdorgao
                  and fd.nuanomesreferencia = fo.nuanomesreferencia
                  and fd.nusequencialfolha = 100 + fo.nusequencialfolha
                  and fd.cdtipofolhapagamento = fo.cdtipofolhapagamento
                  and fd.cdtipocalculo = 2
                where fo.cdfolhapagamento = pCdFolhaAtual) LOOP    

        DBMS_OUTPUT.PUT_LINE ('Folha Antiga - Orgão ' || rec.cdOrgao || ' TfolPag ' || rec.cdTipoFolhaPagamento);
        PKGCMP.PImprimirCC (pCdFolhaPagamento => rec.cdFolhaPagamento, pCdVinculo => pCdVinculo);

        DBMS_OUTPUT.PUT_LINE ('');
        DBMS_OUTPUT.PUT_LINE ('Folha Nova - Orgão ' || rec.cdOrgao || ' TfolPag ' || rec.cdTipoFolhaPagamento);
        PKGCMP.PImprimirCC (pCdFolhaPagamento => pCdFolhaAtual, pCdVinculo => pCdVinculo);
     
    END LOOP;
 END;

 
