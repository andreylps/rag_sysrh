BEGIN  
   PKGCMP.PGerarResumo (pNmCmp => 'NORMAL');
   COMMIT;
END;
/

drop table ECmpCalcApenasUm ;
create table ECmpCalcApenasUm as 
select * from (
select CdPessoa,CdVinculo,CdTipoFolha,CdTipoFolhaPagamento,CdOrgao,
       case
             max(case
               when pago = 'AMBOS' then
                  'OK'
               else
                  'NAO OK'
             end)
         when 'OK' THEN
            'OK'
         else
            case
               when max(pago) <> min(pago) then
                  'OK'
               when max(pago) = 'SÓ ORIGINAL' then
                  'ANTIGA'
               ELSE
                  'NOVA'
            end
         end as FlPagou                
 from ECmpResumo 
where nmCmp = 'NORMAL'
group by CdPessoa,CdVinculo,CdTipoFolha,CdTipoFolhaPagamento,CdOrgao
) where flpagou <> 'OK';


select * from ECmpCalcApenasUm;
 
-- marcando erros aceitaveis

UPDATE ECMPResumo
   SET tem_dif_tolerancia = 2
 WHERE nmCmp = 'NORMAL'
   AND tem_dif_tolerancia = 1
   AND (    
           (CdTipoFolha = 3 AND RUBRICA IN ('09-1010','09-1911') )-- Folha de férias calc primeiro e a base 13 não base
        or (RUBRICA IN ('09-1027','09-1028') ) -- inss de varios vinculos                  
        or (RUBRICA IN ('09-1020','09-1911','09-1021','09-1912') ) -- Base/desc IR de varios vinculos        
      
        or (RUBRICA IN ('09-0909','09-0901') ) -- total de descontos/proventos    
         
       );
;
-- criando tabela de pessoas com erros

drop table tmppessoascomerro;
create table tmppessoascomerro as 
selecT distinct cdpessoa
  from ECmpResumo
 where nmcmp = 'NORMAL'
   and tem_dif_tolerancia = 1;
   
--

drop table ECmpResPessoa;

create table ECmpResPessoa as
select 
nmcmp, 
cdpessoa, 
max(nmrubrica) as nmrubrica, 
max(tprubrica) as tprubrica, 
rubrica, 
max(flduplovinculo) as flduplovinculo,
max(nmpessoa) as nmpessoa, 
sum(vl_origem) as VlOrigem, 
sum(vl_teste) as VlTeste, 
sum(vl_teste) - sum(vl_origem) vl_dif, 
max(tem_teste) tem_teste, 
max(tem_origem) tem_origem, 
CASE
  WHEN Abs( SUM(VL_TESTE) - SUM(VL_ORIGEM)) > 0 THEN
    1
  ELSE
    0
END as TEM_DIF,

CASE
  WHEN Abs( SUM(decode(tem_dif_tolerancia,2,0,VL_TESTE)) - SUM(decode(tem_dif_tolerancia,2,0,VL_ORIGEM))) > 0.02 THEN
     1
  ELSE
    0
END as TEM_DIF_TOLERANCIA
 from ECmpResumo res
where nmcmp = 'NORMAL'
and exists (select 1 from tmppessoascomerro where cdpessoa = res.cdpessoa)

group by nmcmp,cdpessoa, rubrica;
  

-- criando novamente tabela de pessoas com erros

drop table tmppessoascomerro;
create table tmppessoascomerro as 
selecT distinct cdpessoa
  from ECmpResPessoa
 where nmcmp = 'NORMAL'
   and tem_dif_tolerancia = 1;
   
   
-- apagar pessoas que estão 100% iguais

drop table ecmpresumores;
create table ecmpresumores as 
   select * from ecmpresumo res
     where exists (select 1 from tmppessoascomerro where cdpessoa = res.cdpessoa);


delete ECmpResPessoa where cdpessoa not in 
(select cdpessoa from tmppessoascomerro);

-- fim geracao de apuracao das diferencas
   
commit;
        
