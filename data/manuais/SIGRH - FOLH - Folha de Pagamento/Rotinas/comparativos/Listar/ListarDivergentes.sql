-- rubricas a atacar

-- sem duplo vinculo

select NmCmp, min(nmrubrica) as rub, max(cdvinculo),max(cdpessoa),--sum(case when tem_dif = 1 THEN 1 else 0 end) as Tem_DIF,
 sum(case when tem_dif_tolerancia = 1 THEN 1 else 0 end) as Tem_DIFPtolerancia
 from eCmpResumo
where nmCmp = 'NORMAL'
 and flduplovinculo = 0
and tem_dif_tolerancia = 1
and cdagrupamento = 1
and cdtipofolhapagamento = 2
and cdvinculo <> 676057 -- tem problema de inss de 13 de outros anos influenciando no atual
and nmrubrica not like '01-0403%' -- comissao
and nmrubrica not like '09-1028%'
and nmrubrica not like '09-1027%'
group by NmCmp,rubrica
order by 1,4 desc;


-- pessoas com a rubrica

select distinct cdvinculo
from  eCmpResumo
where nmCmp = 'NORMAL'
and tem_dif_tolerancia = 1
and nmrubrica like '05-0544%'



-- pessoa selecionada

selecT * from eCmpResumo
where nmCmp = 'NORMAL'
 and tem_dif = 1
and cdpessoa = 1279683



select distinct cdvinculo from vpagcc
where nuanomesreferencia = 202505
and cdpessoa = 1322307

selecT * from etrbrecolhimentoavulso
where cdpessoa = 901782 or cdvinculo = 901782;

selecT * from etrbrecolhimentoavulso13
where cdpessoa = 901782;


-- Duplo Vinculo


select cdpessoa, rubrica, sum(vl_dif) as vldiferenca
from eCmpResumo
where nmCmp = 'NORMAL'
  and tem_dif = 1
  and flduplovinculo = 1
group by cdpessoa,rubrica;

update eCmpResumo
   set tem_Dif_tolerancia = 2
where (cdpessoa,rubrica) 
  in (
select cdpessoa, rubrica
 from tmpcmppessoa
where abs(vldiferenca) <= 0.02
);

select NmCmp, min(nmrubrica) as rub, max(cdvinculo),sum(case when tem_dif = 1 THEN 1 else 0 end) as Tem_DIF,
 sum(case when tem_dif_tolerancia = 1 THEN 1 else 0 end) as Tem_DIFPtolerancia,
 sum(case when tem_dif_tolerancia = 2 THEN 1 else 0 end) as Tem_DIFDuploAceita
 from eCmpResumo
where nmCmp = 'NORMAL'
 and flduplovinculo = 1
and tem_dif = 1
group by NmCmp,rubrica
order by 1,4 desc;

-- um exemplo

selecT * from eCmpResumo ext
where nmCmp = 'NORMAL'
 and tem_dif_tolerancia = 1
and flduplovinculo = 1
--and rubrica  = '05-0516'
and exists (select 1 from ecmpduplovinc where cdpessoa = ext.cdpessoa and qtde = 2)
and cdpessoa = 149041


select * from etrbrecolhimentoavulso where cdvinculo = 1058584 or cdpessoa = 149041;
select * from etrbrecolhimentoavulso13 where cdpessoa = 149041;


select * from vpagcc
where nurubricafmt = '05-0512'
and 
cdpessoa = 149041
and cdtipocalculo in (1,5)
and nuanomesreferencia = 202505



selecT * from epagfolhapagamento
where cdfolhapagamento in (507035,507046);
