-- fixar inss13 quando tem dev. inss de anos anteriores

insert into ecmpAcertoRubrica (cdorgao,cdvinculo,cdrubricaagrupamento,nusufixorubrica,NmCmp,demotivo)

selecT ext.cdorgao,ext.cdvinculo,ext.cdrubricaagrupamento,  ext.nusufixorubrica,
       'NORMAL','PAR COMISSSAO'

from eCmpResumo ext
where nmCmp = 'NORMAL'
 and tem_dif = 1
and flduplovinculo = 0
and rubrica  like '01-0403%'

 
