drop table ECmpResumoDV;
create table ECmpResumoDV as 
select * from eCmpResumo
where nmCmp = 'NORMAL'
 and flduplovinculo = 1;
 
 
update eCmpResumoDV
   set tem_Dif_tolerancia = 0
where tem_dif_tolerancia = 1
  and (cdpessoa,rubrica) 
        in (
      select cdpessoa, rubrica
       from tmpcmppessoa
      where abs(vldiferenca) <= 0.02
      );

delete eCmpResumoDV
where cdpessoa not in
      (
      select distinct cdpessoa
       from ECmpResumoDV
      where tem_dif_tolerancia = 1);

alter table eCmpResumoDV add (flLiquidoOK  INTEGER);

update eCmpResumoDV
   set flLiquidoOK = 1;
   
update eCmpResumoDV
   set flLiquidoOK = 0
where cdpessoa 
  in (
select distinct cdpessoa
 from eCmpResumoDV
where tem_dif_tolerancia = 1
 and rubrica not like '09%'
);
 
drop table ecmpcontribindiv;
create table ecmpcontribindiv as
select capa.cdvinculo, capa.cdfolhapagamento
 from epagcapahistrubricavinculo capa 
 inner join epagfolhapagamento fp
 on fp.nuanomesreferencia = 202505
 and fp.cdtipocalculo = 1
 and fp.cdtipofolhapagamento = 2
 and fp.cdfolhapagamento = capa.cdfolhapagamento
where capa.vlpercentcontribindiv  is not null;

delete eCmpResumoDV
where cdpessoa in (1206702,1224836,1187084,69465,149041,253743,227848,290745,247625);

--
 ver vinculo 945718


-- rubricas a atacar

select min(nmrubrica) as rub, max(decode(tem_dif_tolerancia,1,cdvinculo)),sum(case when tem_dif = 1 THEN 1 else 0 end) as Tem_DIF,
 sum(case when tem_dif_tolerancia = 1 THEN 1 else 0 end) as Tem_DIFtolerancia
 from eCmpResumoDV
where tem_dif = 1
group by rubrica
order by 4 desc;



select flliquidook, count (*), count (distinct cdpessoa)
from eCmpResumoDV
group by flliquidook;

-- rubricas de diferencas das pessoas com diferenca de liquido

select cdpessoa, min(nmrubrica) as rub, max(decode(tem_dif_tolerancia,1,cdvinculo)),sum(case when tem_dif = 1 THEN 1 else 0 end) as Tem_DIF,
 sum(case when tem_dif_tolerancia = 1 THEN 1 else 0 end) as Tem_DIFtolerancia
 from eCmpResumoDV
where tem_dif = 1
and flliquidook = 0
and nmrubrica not like '09%'
group by cdpessoa, rubrica
order by 1,2 desc;

-- batimento de 1 pessoa

select fp.deordemexecucao, capa.nuordemcalculo, c.cdorgao,c.cdvinculo,nurubricafmt, descricao, vlpagamento,cdhistoricorubricavinculo
from vpagcc c
inner join epagfolhapagamento fp
  on fp.cdfolhapagamento = c.cdfolhapagamento
left join epagcapahistrubricavinculo capa
  on capa.cdfolhapagamento = fp.cdfolhapagamento
 and capa.cdvinculo = c.cdvinculo
where cdpessoa = 1104209
and c.cdtipocalculo in (1,5)
and c.nuanomesreferencia = 202505
--and c.cdagrupamento <> 1
--and nurubricafmt in ('05-0512','09-0903')
order by 1,2,3,4,5;


select cdorgao,dv.cdvinculo,nmrubrica,vl_origem, vl_teste, deordemexecucao_teste,cdfolhateste, capa.vlpercentcontribindiv, capa.nuordemcalculo
from eCmpResumoDV dv
left join epagcapahistrubricavinculo capa
  on capa.cdfolhapagamento = dv.cdfolhateste
 and capa.cdvinculo = dv.cdvinculo

where cdpessoa = 1104209
and (  tem_dif = 1 
--or nmrubrica like '09-0903%'

)
order by deordemexecucao_teste;




-- Listar CC Duplo Vinculo


select max(r.nurubricafmt) || '-' || lpad ( max(nusufixorubrica),2,'0') as Rubrica, 
       case when sum(decode (cdtipocalculo,2,vlpagamento,0) ) <> sum(decode (cdtipocalculo,1,vlpagamento,0) ) then
          '** '
       end || max(r.derubricaagrupamentofmt) as descricao, 
       sum(decode (cdtipocalculo,2,vlpagamento,0) ) as folhaAntiga,
       sum(decode (cdtipocalculo,1,vlpagamento,0) ) as folhaNova,      
       max(h.cdrubricaagrupamento), min(h.cdvinculo), max(h.cdvinculo)
  from epaghistoricorubricavinculo h
 inner join vpagrubricaagrupamento r
    on r.cdrubricaagrupamento = h.cdrubricaagrupamento
 inner join epagfolhapagamento fp
    on fp.cdfolhapagamento = h.cdfolhapagamento
 inner join ecadvinculo v
    on v.cdvinculo = h.cdvinculo 
 where fp.nuanomesreferencia = 202505
   and fp.cdtipocalculo in (1,2)
   and v.cdpessoa = 298831
 group by h.cdrubricaagrupamento, nusufixorubrica
  order by 1
 
 
-- trib 
 select * from vpagcc
where nuanomesreferencia = 202505
and cdtipocalculo = 2
and cdpessoa  =  298831
and (descricao like '%IR%' or descricao like '%INSS%' or descricao like '%I N S S%')
and (descricao not like '%13%')
and (descricao not like '%PATR%')
order by cdvinculo, nurubricafmt;
