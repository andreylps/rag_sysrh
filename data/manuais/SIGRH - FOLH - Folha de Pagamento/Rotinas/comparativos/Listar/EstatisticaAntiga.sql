SELECT t.*,
       trunc (100 * duplook / (duplook + duplodif),2) || ' %' as PDUPLOOK,
       trunc (100 * unicook / (unicook + unicodif),2)  || ' %' as PUNICOOK
   from (select nmCmp,
               decode (o.cdagrupamento,1,'AGPE','OUTROS') as agrup,
               decode (z.cdtipofolha,1,'MENSAL','OUTRAS') as tipo,
               trunc(SYSDATE) as hoje,
               sum(decode(tem_dif_tolerancia,0,decode (flDuploVinculo,1,1,0),0)) as DUPLOOK ,
               sum(decode(tem_dif_tolerancia,1,decode (flDuploVinculo,1,1,0),0)) as DUPLODIF,
               sum(decode(tem_dif_tolerancia,0,decode (flDuploVinculo,0,1,0),0)) as UNICOOK ,
               sum(decode(tem_dif_tolerancia,1,decode (flDuploVinculo,0,1,0),0)) as UNICODIF
               from eCmpResumo z
              inner join vcadorgao o 
                 on o.cdorgao = z.cdorgao
              left join epagtipofolhapagamento tfp
                 on tfp.cdtipofolhapagamento = z.cdtipofolhapagamento -- nvl(z.cdtipofolhapag_origem,z.cdtipofolhapag_teste)  
                 
              where z.nmCmp = 'NORMAL'                    
              group by nmCmp,decode (o.cdagrupamento,1,'AGPE','OUTROS'), 
              
              decode (z.cdtipofolha,1,'MENSAL','OUTRAS') 
              
              ) t;

 

