declare

   pDtInicioMes   date := '01/05/2025';
   pDtFimMes      date := '30/05/2025';
 
/*
create table tmpcmpdepvinc
              (Cdorgao        integer,
               CdVinculo      integer,
               CdPessoa       integer,
               QtdeDepAntiga  integer,
               QtdeDepNova    integer);
                
create table tmpcmpdepdep
              (CdVinculo      integer,
               nmDependente   VARCHAR2(80),
               dtNasc         date,
               QtdeAntiga     integer,
               QtdeNova       integer);

*/  
   TYPE rDep IS RECORD (
      nmDependente varchar2(80),
      dtNasc       DATE,
      qtdeAntiga   INTEGER,
      qtdeNova     INTEGER
   );
        
   TYPE tlstDep     IS TABLE OF rDep
      INDEX BY VARCHAR2(200);
      
   vLstDep          tLstDep; 
   vChaveDep        VARCHAR2(200); 
   
   vContDepNova     INTEGER;
   vContDepAntiga   INTEGER;
   
begin
   
   delete tmpcmpdepvinc;
   delete tmpcmpdepdep;            
   
   FOR vrec in (select o.cdagrupamento, o.cdorgao, v.cdpessoa, v.cdvinculo
               from ecadvinculo v
              inner join vcadorgao o
                 on o.cdorgao = v.cdorgao
                 
              where (v.dtdesligamento is null or v.dtdesligamento >= pDtInicioMes)
                and v.dtadmissao <= pDtFimMes
       
            --    and v.cdvinculo = 327899           
                
              order by o.cdagrupamento, o.cdorgao, v.cdpessoa, v.cdvinculo                 
                ) LOOP
                
      -- Rotina Nova       
      
      vContDepNova    := 0;
      vContDepAntiga  := 0;  
      vLstDep.DELETE;    

      for dep in (SELECT DI.CdDependenteVinculoIRRF,
                              D.CdDependente,
                              D.NmDependente,
                              DtNascimento,
                              DI.DtFimDependencia,
                              DI.FlEstudante,
                              D.FlInvalidez,
                              GP.FlFinalizaDependenciaIRRF,
                              GP.FlPensaoVitalicia,
                              d.Nucpf,
                              o.cdAgrupamento
                         FROM ECadDependenteVinculo DV
                        INNER JOIN ECadDependenteVinculoIRRF DI
                           ON DV.CdDependenteVinculo =
                              DI.CdDependenteVinculo
                        INNER JOIN ECadPessoaDependente PD
                           ON PD.CdDependente = DV.CdDependente
                        INNER JOIN ECadDependente D
                           ON D.CdDependente = PD.CdDependente
                        INNER JOIN ECadGrauParentescoprevfin GP
                           ON GP.CdGrauParentescoPrevFin =
                              PD.CdGrauParentescoPrevFin
                          
                        INNER JOIN ECadVinculo V
                           ON V.CdVinculo = dv.CdVinculo
                           
                        INNER JOIN VCadOrgao o
                           ON o.CdOrgao = v.CdOrgao   
 
                         LEFT JOIN EAfaRegistroObito RO
                           ON RO.CdDependente = DV.CdDependente
                          AND RO.FlAnulado = 'N'
                         
                        WHERE PD.CdResponsavel = vrec.CdPessoa
                          AND DI.DtInicioDependencia <= pDtFimMes
                          AND (DI.DtFimdependencia >= pDtInicioMes OR DI.DtFimDependencia IS NULL)                             
                          AND (ro.DtObito IS NULL OR ro.DtObito >= pDtInicioMes) 
                              
                          -- será por pessoa dentro do agrupamento AND V.Cdvinculo = pTributacao.CdVinculo
                          AND o.cdagrupamento = vrec.CdAgrupamento
                          AND V.CdPessoa = PD.CdResponsavel
                          AND ( V.CdVinculo = vrec.CdVinculo
                                OR ( v.dtAdmissao <= pDtFimMes
                                     AND (v.dtDesligamento >= pDtInicioMes OR v.dtdesligamento IS NULL)
                                   )
                               )
                          
                        ORDER BY D.CdDependente) LOOP          
         
         vChaveDep := to_char(dep.dtNascimento,'YYYYMMDD') || dep.nmdependente;
         
         IF vLstDep.EXISTS (vChaveDep) THEN
            vLstDep(vChaveDep).qtdeNova    := vLstDep(vChaveDep).qtdeNova + 1;
         ELSE
            
            vContDepNova := vContDepNova + 1;
            vLstDep(vChaveDep).nmdependente := dep.nmdependente;
            vLstDep(vChaveDep).dtNasc       := dep.dtNascimento;
            vLstDep(vChaveDep).qtdeAntiga   := 0;
            vLstDep(vChaveDep).qtdeNova     := 1;            
            
         END IF; 
                       
      end loop;
                              
      -- antiga
      
      for dep in (SELECT DI.CdDependenteVinculoIRRF,
                               D.CdDependente,
                               D.NmDependente,
                               DtNascimento,
                               DI.DtFimDependencia,
                               DI.FlEstudante,
                               D.FlInvalidez,
                               GP.FlFinalizaDependenciaIRRF,
                               GP.FlPensaoVitalicia
                          FROM ECadDependenteVinculo DV
                         INNER JOIN ECadDependenteVinculoIRRF DI
                            ON DV.CdDependenteVinculo = DI.CdDependenteVinculo
                         INNER JOIN ECadPessoaDependente PD
                            ON PD.CdDependente = DV.CdDependente
                         INNER JOIN ECadDependente D
                            ON D.CdDependente = PD.CdDependente
                         INNER JOIN ECadGrauParentescoprevfin GP
                            ON GP.CdGrauParentescoPrevFin = PD.CdGrauParentescoPrevFin

                         INNER JOIN ECadVinculo V
                            ON V.CdVinculo = dv.CdVinculo

                         WHERE PD.CdResponsavel =  vrec.CdPessoa
                           AND DI.DtInicioDependencia <= pDtFimMes
                           AND (DI.DtFimdependencia >= pDtInicioMes OR
                               DI.DtFimDependencia IS NULL)
                           AND V.Cdvinculo = vrec.CdVinculo
                           AND V.CdPessoa = PD.CdResponsavel
                           AND NOT EXISTS
                         (SELECT 1
                                  FROM EAfaRegistroObito RO
                                 WHERE RO.CdDependente = DV.CdDependente
                                   AND RO.FlAnulado ='N')
                           AND EXISTS
                         (SELECT 1
                                  FROM ecadvinculo v
                                 INNER JOIN ecadorgao o
                                    ON v.cdorgao = o.cdorgao
                                 WHERE v.cdvinculo = DV.CdVinculo
                                   AND (v.dtDesligamento >= pDtInicioMes OR
                                       v.dtdesligamento IS NULL)
                                   AND o.cdagrupamento = vrec.CdAgrupamento)

                         ORDER BY D.CdDependente) LOOP

         vChaveDep := to_char(dep.dtNascimento,'YYYYMMDD') || dep.nmdependente;

         vContDepAntiga := vContDepAntiga + 1;
                     
         IF vLstDep.EXISTS (vChaveDep) THEN
            vLstDep(vChaveDep).qtdeAntiga   := vLstDep(vChaveDep).qtdeAntiga + 1;
         ELSE          

            vLstDep(vChaveDep).nmdependente := dep.nmdependente;
            vLstDep(vChaveDep).dtNasc       := dep.dtNascimento;
            vLstDep(vChaveDep).qtdeAntiga   := 1;
            vLstDep(vChaveDep).qtdeNova     := 0;            
            
         END IF; 

      END LOOP;
            
      IF NOT ( vContDepAntiga = vContDepNova AND vContDepAntiga = 0) THEN
                      
         INSERT INTO tmpcmpdepvinc
              (Cdorgao,
               CdVinculo,
               CdPessoa,
               QtdeDepAntiga,
               QtdeDepNova)
           VALUES
              (vrec.Cdorgao,
               vrec.CdVinculo,
               vrec.CdPessoa,
               vContDepAntiga,
               vContDepNova);
                                  
         vChaveDep := vLstDep.FIRST;
         
         WHILE vChaveDep IS NOT NULL LOOP
               
            INSERT INTO tmpcmpdepdep
                 (CdVinculo,
                  nmDependente,
                  dtNasc,
                  QtdeAntiga,
                  QtdeNova)
              VALUES
                 (vrec.CdVinculo,
                  vLstDep(vChaveDep).nmDependente,
                  vLstDep(vChaveDep).dtNasc,
                  vLstDep(vChaveDep).QtdeAntiga,
                  vLstDep(vChaveDep).QtdeNova);
    
             vChaveDep := vLstDep.NEXT(vChaveDep);
         
         END LOOP;
 
      END IF;
           
   END LOOP;
   
end;
/
selecT case 
        when qtdedepantiga = qtdedepnova then
           'OK'
        else
           'ERRO'
       end, count (*) 
from tmpcmpdepvinc
group by case 
        when qtdedepantiga = qtdedepnova then
           'OK'
        else
           'ERRO'
       end;
       
-- relatorio
select v.cdorgao, v.cdpessoa, d.*  
  from tmpcmpdepvinc v
 inner join tmpcmpdepdep d
   on d.cdvinculo = v.cdvinculo
 where v.qtdedepantiga <> v.qtdedepnova
 order by  v.cdorgao, v.cdpessoa, v.cdvinculo;    
  
 
-- pessoas consideradas mais de uma vez
select * from ( 
 select v.cdpessoa, d.nmdependente, d.dtnasc,
 sum(qtdeantiga) as qtdeantiga,
 max(case when qtdenova >= 1 then 1 else 0 end) as qtdenova
  from tmpcmpdepvinc v
 inner join tmpcmpdepdep d
   on d.cdvinculo = v.cdvinculo
 --where v.cdpessoa = 67509
 group by v.cdpessoa, d.nmdependente, d.dtnasc
 )
 where qtdeantiga <> qtdenova;
       
       
       
       
       
       






