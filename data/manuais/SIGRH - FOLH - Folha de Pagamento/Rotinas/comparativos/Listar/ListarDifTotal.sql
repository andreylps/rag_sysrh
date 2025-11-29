-- apaga pessoas que tem dif de inss que extrapolou o teto

delete ECmpResPessoa
where cdpessoa in (
select cdpessoa from ECmpResPessoa
where nmCmp = 'NORMAL' and tem_dif_tolerancia = 1 
and ( nmrubrica like '05-0512%' or  nmrubrica like '05-0513%')
and vlorigem > vlteste
and vlteste = 951.62);

-- apaga quem recolhe pelo teto avulso e tem dif de inss e o inss teste = 0

delete ECmpResPessoa
where cdpessoa in (
selecT cdpessoa from ECmpResPessoa
where nmrubrica like '05-0512%' 
  and vlteste = 0
  and cdpessoa in (select cdpessoa
                             from etrbrecolhimentoavulso T         
                            where FlAnulado = 'N'
                              and CdObjetoRecolhimento = 1
                              AND (NuAnoInicio < 2025 OR (NuAnoInicio = 2025 AND NuMesInicio <= 05)) 
                              AND (NuAnoFim    > 2025 OR (NuAnoFim    = 2025 AND NuMesFim    >= 05) OR NuAnoFim IS NULL)
                              AND (FlRecolhimentoTeto = 'S')
                              AND NuCNPJ IS NOT NULL
                              )
);                              
                              

-- qtde pessoas com diferenca

select sysdate,
       sum(case when flduplovinculo = 1 and flliq = 0 then 1 else 0 end) as qtPesDuploTotalizadora,
       sum(case when flduplovinculo = 0 and flliq = 0 then 1 else 0 end) as qtSimplesTotalizadora,
       sum(case when flduplovinculo = 1 and flliq = 1 then 1 else 0 end) as qtPesDuploLiquido,
       sum(case when flduplovinculo = 0 and flliq = 1 then 1 else 0 end) as qtSimplesLiquido,
       min(difliq) as MenorDifLiq,
       max(difliq) as MaiorDifLiq,
       sum(abs(difliq)) as TotalDif     

   from (      
         select NmCmp, 
                flduplovinculo,
                cdpessoa,
                max(case when rubrica like '09%' then 0 else 1 end) as flliq,
                sum(case when rubrica like '09-0902%' then vlteste - vlorigem else 0 end) as difLiq
              
          from ECmpResPessoa
         where nmCmp = 'NORMAL'
          and tem_dif_tolerancia = 1 
         group by NmCmp, 
                flduplovinculo,
                cdpessoa);


-- Rubricas a atacar

select NmCmp, min(nmrubrica) as rub, count(distinct cdpessoa) as qtPessoas, max(cdpessoa), 
 sum(case when tem_dif_tolerancia = 1 THEN 1 else 0 end) as ComDiferenca
 from ECmpResPessoa
where nmCmp = 'NORMAL' and tem_dif_tolerancia = 1 
 and flduplovinculo = 0
group by NmCmp,rubrica
order by 1,ComDiferenca desc;


select * from ECmpResPessoa
where nmCmp = 'NORMAL' and tem_dif_tolerancia = 1 
and ( nmrubrica like '05-0512%' or  nmrubrica like '05-0513%')
and flduplovinculo = 0

278709
219093


-- pessoa a tratar

selecT * from eCmpResumoRes RES
where nmCmp = 'NORMAL'
 and tem_dif_tolerancia = 1
 and flduplovinculo = 0
 and rubrica like '05-0516%'
and not exists (select 1 from eCmpResumoRes where cdpessoa = res.cdpessoa and tem_dif_tolerancia = 1 AND rubrica <> res.rubrica
                   and rubrica not like '09%'
               );
               



select * from epagtipofolhapagamento where cdtipofolhapagamento = 609
