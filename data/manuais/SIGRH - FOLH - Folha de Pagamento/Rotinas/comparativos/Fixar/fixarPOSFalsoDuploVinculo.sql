-- fixar falso duplo vinculo

insert into ecmpAcertoRubrica (cdorgao,cdvinculo,cdrubricaagrupamento,nusufixorubrica,flCalculo,NmCmp,demotivo)
selecT ext.cdorgao,ext.cdvinculo,ext.cdrubricaagrupamento, ext.nusufixorubrica,
       'N','NORMAL','DUPLO VINCULO PAGO ' || ext.pago
 from eCmpResumo ext
where tem_dif = 1
  and ext.flduplovinculo = 0
  and ( rubrica like '09-1028%'
     or rubrica like '09-1027%');
     

delete  ecmpAcertoRubrica
where demotivo like 
'DUPLO VINCULO PAGO %';
