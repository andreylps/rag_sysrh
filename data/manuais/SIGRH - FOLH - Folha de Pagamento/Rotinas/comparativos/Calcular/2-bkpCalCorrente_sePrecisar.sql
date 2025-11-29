
-- mudar backp para considerar somente registros da tabela acima

drop table tmpbkprelvinc;
create table tmpbkprelvinc as 
select hrv.* from epagfolhapagamento fp
 inner join epaghistoricorubricarelvinc hrv
   on fp.cdfolhapagamento = hrv.cdfolhapagamento
 where fp.nuanomesreferencia = 202505
   and cdtipocalculo = 1
   and hrv.cdvinculo in (select cdvinculo from tmpxpes);
   
drop table tmpbkphrv;
create table tmpbkphrv as 
select hrv.* from epagfolhapagamento fp
 inner join epaghistoricorubricavinculo hrv
   on fp.cdfolhapagamento = hrv.cdfolhapagamento
 inner join ecadvinculo v
   on v.cdvinculo = hrv.cdvinculo  
 where fp.nuanomesreferencia = 202505
   and cdtipocalculo = 1
   and hrv.cdvinculo in (select cdvinculo from tmpxpes);
   
drop table tmpbkpcapa; 
create table tmpbkpcapa as 
select hrv.* from epagfolhapagamento fp
 inner join epagcapahistrubricavinculo hrv
   on fp.cdfolhapagamento = hrv.cdfolhapagamento
 inner join ecadvinculo v
   on v.cdvinculo = hrv.cdvinculo  
 where fp.nuanomesreferencia = 202505
   and cdtipocalculo = 1
   and hrv.cdvinculo in (select cdvinculo from tmpxpes);

