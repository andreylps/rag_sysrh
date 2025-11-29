-- fixar 5571
insert into ecmpAcertoRubrica (cdorgao,cdvinculo,cdrubricaagrupamento,nusufixorubrica,NmCmp,demotivo)

selecT ext.cdorgao,ext.cdvinculo,ext.cdrubricaagrupamento, ext.nusufixorubrica,,
       'NORMAL','5571 E OUTRA'

from eCmpResumo ext
where nmCmp = 'NORMAL'
 and tem_dif = 1
and flduplovinculo = 0
and cdvinculo = 676057

