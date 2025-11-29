DROP TABLE tmpcmpduplovinc;
create table tmpcmpduplovinc as
select cdpessoa, COUNT (*) as QTDE
from (SELECT DISTINCT CDPESSOA, HRV.CDVINCULO 
        FROM EPAGHISTORICORUBRICAVINCULO hrv
       INNER JOIN ECADVINCULO V
          ON HRV.CdVinculo = V.CdVinculo
       INNER JOIN EPAGFOLHAPAGAMENTO FP
          ON FP.CdFOLHAPAGAMENTO = HRV.CDFOLHAPAGAMENTO
       WHERE FP.NUANOMESREFERENCIA = 202505 
         AND fp.cdTipoCalculo NOT IN (7,8,9,10,11)  
      )
group by cdpessoa     
having COUNT (*) > 1      
;
CREATE INDEX  INDXTMPDUPVINC ON tmpcmpduplovinc(CDPESSOA);     

