-- fixar inss13 quando tem dev. inss de anos anteriores

insert into ecmpAcertoRubrica (cdorgao,cdvinculo,cdrubricaagrupamento,nusufixorubrica,NmCmp,demotivo)

with vinc as 
(selecT cdvinculo from eCmpResumo ext where flduplovinculo = 0 and tem_dif_tolerancia = 1 and rubrica like '05-0513%'
)

selecT ext.cdorgao,ext.cdvinculo,ext.cdrubricaagrupamento, ext.nusufixorubrica,
       'NORMAL','INSS13 - DEV ANOS ANT' 
  from eCmpResumo ext
 where tem_dif = 1
  and rubrica like '05-0513%'
  and cdvinculo in
(
select cdvinculo--, sum(vlbaseano) as vlbaseano, sum(vlbasemes) as vlbasemes
  from (selecT cdvinculo, vl_Teste as vlbaseano, 0 as vlbasemes
          from eCmpResumo ext
         where flduplovinculo = 0
         and tem_dif = 0
         and rubrica like '09-2113%'
         and cdvinculo in (select cdvinculo from vinc)
         
         union all

         selecT cdvinculo, 0 , vl_Teste
          from eCmpResumo ext
         where flduplovinculo = 0
           and tem_dif = 0
         and rubrica like '09-0015%'
         and cdvinculo in (select cdvinculo from vinc)
       )
group by cdvinculo
having sum(vlbaseano) < sum(vlbasemes)
)
;
