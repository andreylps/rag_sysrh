create or replace package PKGTESTE is

PROCEDURE POrdenarFolhaPagamento (pNuAnoMesReferencia IN INTEGER, pCdFolPagDef IN INTEGER DEFAULT NULL);

end PKGTESTE;
/
create or replace package body PKGTESTE is

PROCEDURE POrdenarFolhaPagamento (pNuAnoMesReferencia IN INTEGER, pCdFolPagDef IN INTEGER DEFAULT NULL) IS

   vNuSeq             INTEGER; 
   vDeOrdemExecucao   VARCHAR2(5);
  
BEGIN
   vNuSeq := 0;
   
   FOR fp IN ( with tOrdemOrg as (
                                 select CdOrgao,
                                        row_number() over (order by NuOrdemAgrupamento, NuOrdemOrgaoAgrup) as NuOrdemOrgao
                                   from ( select o.cdOrgao,
                                                 decode (CdAgrupamento, 276,   1, -- IMETRO
                                                                        176,   2, -- DPSC
                                                                        134,   3, -- PMSC
                                                                        1,     4, -- AGPE
                                                                        7,     5, -- MP
                                                                        6,     6, -- SANTUR
                                                                        132,   7, -- PensoesIPREV
                                                                        4,     8, -- CIDASC
                                                                        2,     9, -- CIASC
                                                                        5,    10, -- EPAGRI
                                                                        136,  11, -- SCPA
                                                                              99) as NuOrdemAgrupamento,
                                                 row_number() over (partition by CdAgrupamento order by CdOrgao) as NuOrdemOrgaoAgrup
                                             from vCadOrgao o
                                             ))
                                             
               SELECT fp.CdFolhaPagamento, fp.CdOrgao, FlCalculoDefinitivo, DeOrdemExecucao, fp.rowid as rid
                 FROM epagfolhapagamento fp
                INNER JOIN tOrdemOrg oo
                   ON oo.cdOrgao = fp.cdOrgao
                WHERE NuAnoMesReferencia = 202505
                ORDER BY DECODE(FlCalculoDefinitivo,'S',NVL(fp.DeOrdemExecucao,'D9999'),'N'), NuOrdemOrgao, fp.cdTipoFolhaPagamento, fp.NuSequencialFolha) LOOP
 
      IF fp.FlCalculoDefinitivo = 'S' THEN
         IF fp.DeOrdemExecucao IS NULL THEN
            IF pCdFolPagDef = fp.CdFolhaPagamento THEN 
               vNuSeq := vNuSeq + 1;
               vDeOrdemExecucao := 'D' || LPAD (vNuSeq,4,'0');
            ELSE
               vDeOrdemExecucao := NULL;
            END IF;   
         ELSE   
            vDeOrdemExecucao := fp.DeOrdemExecucao;            
            vNuSeq := SUBSTR(fp.DeOrdemExecucao,2);
         END IF;
      ELSE
         vNuSeq := vNuSeq + 1;
         vDeOrdemExecucao := 'N' || LPAD (vNuSeq,4,'0');
         
      END IF;
      
      IF  NVL(fp.DeOrdemExecucao,'X') <> vDeOrdemExecucao THEN
         
dbms_output.put_line ('cdfol/orgao/def: ' || fp.cdfolhapagamento || '/' || fp.cdorgao || '/' || fp.flcalculodefinitivo
 || ' -> de ' || fp.deordemexecucao || ' para ' || vDeOrdemExecucao);
END IF;


      IF NVL(fp.DeOrdemExecucao,'X') <> vDeOrdemExecucao THEN
         UPDATE EPagFolhaPagamento
               SET DeOrdemExecucao = vDeOrdemExecucao
             WHERE RowId = fp.rid;
      END IF;
       
   END LOOP;

END;




end PKGTESTE;
/
