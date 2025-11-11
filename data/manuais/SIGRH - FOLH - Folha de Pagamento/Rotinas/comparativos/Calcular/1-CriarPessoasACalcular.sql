-- criando pessoas a recalcular

drop table tmpxpes;

create table tmpxpes as
select distinct fp.cdAgrupamento,
                fp.cdtipocalculo,  
                fp.cdtipofolhapagamento, 
                fp.nuanomesreferencia, 
                fp.nuanoreferencia,
                fp.numesreferencia,
                fp.nusequencialfolha, 
                fp.cdorgao,
                fp.cdfolhapagamento,
                fp.dtCalculo,
                fp.dtPrevisaoCredito,
                cdvinculo,
                cdpessoa
           from eCmpResumo r
     inner join epagfolhapagamento fp
        on fp.nuanomesreferencia = 202505
       and fp.cdorgao = r.cdorgao
       and fp.cdtipofolhapagamento = r.cdtipofolhapagamento
       and fp.cdtipocalculo = 1
       and fp.nusequencialfolha = r.nuseqfolhacomum    

     where cdpessoa in (select distinct cdpessoa 
                         from eCmpResumorES where tem_dif = 1
                        /*  and (   nmrubrica like '09-0910%'
                               or nmrubrica like '05-0516%'
                               or nmrubrica like '05-0544%'
                               or nmrubrica like '05-0546%'
                              )  
                         */            
                         )
/*                                    
     where cdpessoa in (select distinct cdpessoa 
                         from eCmpResumo where tem_dif = 1
                          and (  nmrubrica like '05-0515%'
                              or nmrubrica like '05-0516%'
                              or nmrubrica like '09-1666%'
                              or nmrubrica like '09-1019%'
                              or nmrubrica like '09-1006%'
                              or nmrubrica like '09-1005%'
                          )             
                         )
*/
/*
     where flduplovinculo = 0 and tem_dif = 1
       and (  nmrubrica like '05-0544%'
           or nmrubrica like '09-0516%'
           )

*/
;
