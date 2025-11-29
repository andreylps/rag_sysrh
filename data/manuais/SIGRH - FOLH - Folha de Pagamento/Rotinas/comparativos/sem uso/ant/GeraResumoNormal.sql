drop table tmpcmp ;

create table tmpcmp as
with visao as (
       SELECT 
               NmCmp,
               CdOrgao,
               CdVinculo,
               MAX(CdPessoa) as cdPessoa,
               MAX(FlDuploVinculo) as FlDuploVinculo,
               MAX(Rubrica || ' - ' || DescricaoRubrica) as Rubrica,
               MAX(TPRUBRICA) as TpRubrica,
               MAX(Matr) AS Matr,
               MAX(NmPessoa) as NmPessoa,
               SUM(INDICE_ORIGEM) AS INDICE_ORIGEM,
               SUM(VL_ORIGEM) as VL_ORIGEM,
               SUM(INDICE_TESTE) AS INDICE_TESTE,
               SUM(VL_TESTE) as VL_TESTE,             
               SUM(VL_TESTE) - SUM(VL_ORIGEM) AS VL_DIF,
               SUM (TEM_TESTE) AS TEM_TESTE,
               SUM (TEM_ORIGEM) AS TEM_ORIGEM,
               CASE
                  WHEN SUM (TEM_TESTE) > 0 AND SUM (TEM_ORIGEM) > 0 THEN
                    'AMBOS'
                  WHEN  SUM (TEM_TESTE) > 0 THEN
                    'SÓ TESTE'
                  ELSE
                    'SÓ ORIGINAL'
               END AS PAGO,     

               CASE
                 WHEN Abs( SUM(VL_TESTE) - SUM(VL_ORIGEM)) > 0 THEN
                   1
                 ELSE
                   0
               END as TEM_DIF,
                           
               CASE
                 WHEN Abs( SUM(VL_TESTE) - SUM(VL_ORIGEM)) > MAX (VLDIFERENCA) THEN
                   1
                 ELSE
                   0
               END as TEM_DIF_TOLERANCIA,
               MAX(NuMatricula) as NuMatricula,
               MAX(NuDvMatricula) as NuDvMatricula,
               MAX(NuSeqMatricula) as NuSeqMatricula,
               MAX (CDHRUBRICAVINCULO_ORIGEM) AS CDHRUBRICAVINCULO_ORIGEM,
               MAX (CDHRUBRICAVINCULO_TESTE) AS CDHRUBRICAVINCULO_TESTE,
               MAX (CDLANCFINANCEIRO_ORIGEM) AS CDLANCFINANCEIRO_ORIGEM,
               MAX (CDLANCFINANCEIRO_TESTE) AS CDLANCFINANCEIRO_TESTE,    
               CdRubricaAgrupamento,
               NuSufixoRubrica                    
               
          FROM (
          
                   SELECT 
                       FP.NmCmp,
                       FP.CdOrgao,           
                       cada39.cdpessoa,  
                       decode (dv.cdpessoa,null,0,1) as flDuploVinculo,         
                       PAGA20.CdRubricaAgrupamento,
                       PAGA20.Nusufixorubrica,
                       CADA39.CdVinculo,
                       lpad(CADA39.NuMatricula, 7, '0') || '-' ||
                       CADA39.NuDVMatricula || '-' ||
                       lpad(CADA39.NuSeqMatricula, 2, '0') AS Matr,
                       NuMatricula,
                       NuDvMatricula,
                       NuSeqMatricula,
                       CADAA1.NmPessoa,
                       PAGA34.NURUBRICAFMT  || '-' || 
                       LPAD(PAGA20.NuSufixoRubrica, 2, '0') AS RUBRICA,
                       PAGA34.DETIPORUBRICAPDT as TPRUBRICA,
                       PAGA34.DERUBRICAAGRUPAMENTOFMT  AS DESCRICAORUBRICA,
                       
                       Decode (FP.TIPO,'O',PAGA20.VlIndiceRubrica,0) AS INDICE_ORIGEM,
                       Decode (FP.TIPO,'O',PAGA20.VlPagamento,0) AS VL_ORIGEM,
                       Decode (FP.TIPO,'T',PAGA20.VlIndiceRubrica,0) AS INDICE_TESTE,
                       Decode (FP.TIPO,'T',PAGA20.VlPagamento,0) AS VL_TESTE,
                       Decode (FP.Tipo,'O',1,0) AS TEM_ORIGEM,
                       Decode (FP.Tipo,'T',1,0) AS TEM_TESTE,

                       Decode (FP.TIPO,'O',PAGA20.CDHISTORICORUBRICAVINCULO,0) AS CDHRUBRICAVINCULO_ORIGEM,
                       Decode (FP.TIPO,'T',PAGA20.CDHISTORICORUBRICAVINCULO,0) AS CDHRUBRICAVINCULO_TESTE,
                       Decode (FP.TIPO,'O',NVL(PAGA20.CDLANCAMENTOFINANCEIRO,0),0) AS CDLANCFINANCEIRO_ORIGEM,
                       Decode (FP.TIPO,'T',NVL(PAGA20.CDLANCAMENTOFINANCEIRO,0),0) AS CDLANCFINANCEIRO_TESTE,
                                    
                       FP.VLDIFERENCA
                       
                       
                  FROM EPAGHISTORICORUBRICAVINCULO PAGA20
                 INNER JOIN ECADVINCULO CADA39
                    ON PAGA20.CdVinculo = CADA39.CdVinculo
                 INNER JOIN ECADPESSOA CADAA1
                    ON CADA39.CdPessoa = CADAA1.CdPessoa

                 INNER JOIN VPAGRUBRICAAGRUPAMENTO PAGA34
                    ON PAGA20.CdRubricaAgrupamento =
                       PAGA34.CdRubricaAgrupamento
                                        
                 LEFT JOIN Ecmpduplovinc DV
                   ON dv.CdPessoa = CADAA1.CdPessoa     
                  AND dv.NmCmp = 'NORMAL' 
                       
                 INNER JOIN ( SELECT 
                                   PARM.NmCmp,
                                   FP.CdOrgao,
                                   CdFolhaPagamento,
                                   PARM.VLDIFERENCA,
                                   CASE  
                                   WHEN (    FP.NuAnoMesReferencia = PARM.NuAnoMesRefOrigem
                                           AND FP.Cdtipofolhapagamento = PARM.CdTipoFolhaPagOrigem
                                           AND FP.cdTipoCalculo = PARM.CDTIPOCALCULOOrigem 
                                           AND ( FP.Nusequencialfolha = PARM.Nusequencialorigem OR  PARM.Nusequencialorigem IS NULL)                                          
                                         ) THEN
                                        'O'
                                   ELSE
                                        'T'
                                   END as Tipo
                                
                                 FROM ECmpParam PARM
                                 
                                 INNER JOIN EPAGFOLHAPAGAMENTO FP
                                    ON  ( (    FP.NuAnoMesReferencia = PARM.NuAnoMesRefOrigem
                                           AND FP.Cdtipofolhapagamento = PARM.CdTipoFolhaPagOrigem
                                           AND FP.cdTipoCalculo = PARM.CDTIPOCALCULOOrigem 
                                           AND ( FP.CdOrgao = PARM.cdOrgao OR PARM.CdOrgao IS NULL)
                                           AND ( FP.Nusequencialfolha = PARM.Nusequencialorigem OR  PARM.Nusequencialorigem IS NULL)
                                          ) OR
                                          (    FP.NuAnoMesReferencia = PARM.NUANOMESREFTeste
                                           AND FP.Cdtipofolhapagamento = PARM.CdTipoFolhaPagTeste
                                           AND FP.cdTipoCalculo = PARM.CdtipocalculoTeste
                                           AND ( FP.CdOrgao = PARM.cdOrgao OR PARM.CdOrgao IS NULL)
                                           AND ( FP.Nusequencialfolha = PARM.NusequencialTeste OR  PARM.NusequencialTeste IS NULL)
                                          )
                                        )
                                 
                                 WHERE Parm.NmCmp = 'NORMAL'
                            ) FP
                            
                    ON FP.CdFolhaPagamento = PAGA20.CdFolhaPagamento
                    
                 -- WHERE PAGA34.Cdtiporubrica <> 9
                 
               )
                   
         GROUP BY NmCmp,
                  CdOrgao,
                  CdVinculo,
                  CdRubricaAgrupamento,
                  NuSufixoRubrica
       
 ORDER BY NmCmp,
          CdOrgao,
          Matr,
          Rubrica
)
 select * from visao;

/*
create index tmpidxcmp on tmpcmp (NmCmp,cdrubricaagrupamento,CDPESSOA, cdvinculo);
create index tmpidx2cmp on tmpcmp  (NmCmp,cdvinculo);
create index tmpidx3cmp on tmpcmp  (NmCmp,CDPESSOA);


SELECT t.*,
       trunc (100 * duplook / (duplook + duplodif),2) || ' %' as PDUPLOOK,
       trunc (100 * unicook / (unicook + unicodif),2)  || ' %' as PUNICOOK,
       trunc (100 * DUPLOOKTOL / (duplook + duplodif),2) || ' %' as PDUPLOOKTOL,
       trunc (100 * UNICOOKTOL / (unicook + unicodif),2)  || ' %' as PUNICOOKTOL       
  from (select NmCmp,
              trunc(SYSDATE) as hoje,
              sum(decode(tem_dif,0,decode (flDuploVinculo,1,1,0),0)) as DUPLOOK ,
              sum(decode(tem_dif,1,decode (flDuploVinculo,1,1,0),0)) as DUPLODIF,
              sum(decode(tem_dif,0,decode (flDuploVinculo,0,1,0),0)) as UNICOOK ,
              sum(decode(tem_dif,1,decode (flDuploVinculo,0,1,0),0)) as UNICODIF,
              sum(decode(tem_dif_tolerancia,0,decode (flDuploVinculo,1,1,0),0)) as DUPLOOKTOL,
              sum(decode(tem_dif_tolerancia,0,decode (flDuploVinculo,0,1,0),0)) as UNICOOKTOL
              from tmpcmp z
              where z.NmCmp = 'NORMAL'
              group by NmCmp
              
              ) t;
*/
 
