update epagrubricaagrupamento
set cdmodalidaderubrica = null
where cdrubricaagrupamento in (37396,8002,48283,25168,29557,36503,37395)


select cdmodalidaderubrica, cdrubricaagrupamento
from epagrubricaagrupamento
where cdrubricaagrupamento in (37396,8002,48283,25168,29557,36503,37395);

25	8002
25	25168
23	29557
99	36503
25	37395
25	37396
2	48283



selecT * from epag




select cdagrupamento,cdorgao,cdmodalidaderubrica, count (*), max(flvigente), min(flvigente)
from vpagrubricaagrupamento
where cdmodalidaderubrica is not null
--and cdagrupamento in (1,4,7,132,134,135)
group by cdagrupamento,cdorgao,cdmodalidaderubrica
having count (*) > 1


begin
   pkgcadcons.PAtualizaMViewSistema(null);
end;



