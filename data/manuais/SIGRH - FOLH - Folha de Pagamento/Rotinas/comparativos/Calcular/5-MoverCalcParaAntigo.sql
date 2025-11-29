drop table tmpxdpfolha;
create table tmpxdpfolha as
      select distinct xp.cdfolhapagamento as cdfolhapagamento,
                      fpo.cdfolhapagamento as cdfolnormal,
                      fpd.cdfolhapagamento as cdfolsim
                 from tmpxpes xp
                  
                inner join epagfolhapagamento fpo
                   on fpo.nuanomesreferencia = xp.nuanomesreferencia
                  and fpo.cdtipofolhapagamento = xp.cdtipofolhapagamento 
                  and fpo.cdorgao = xp.cdorgao
                  and fpo.nusequencialfolha = xp.nusequencialfolha
                  and fpo.cdtipocalculo = xp.cdtipocalculo

                inner join epagfolhapagamento fpd
                   on fpd.nuanomesreferencia = fpo.nuanomesreferencia
                  and fpd.cdtipofolhapagamento = fpo.cdtipofolhapagamento 
                  and fpd.cdorgao = fpo.cdorgao
                  and fpd.nusequencialfolha = fpo.nusequencialfolha + 100
                  and fpd.cdtipocalculo = 2
;                

-- copiar folha corrente para antiga

begin
   for rec in (select distinct hrv.cdvinculo,
                               cdfolnormal,
                               cdfolsim
                 from tmpxpes hrv
                 
                inner join tmpxdpfolha fp
                  on fp.cdfolhapagamento = hrv.cdfolhapagamento
                 
               ) loop
                  

      delete epagcapahistrubricavinculo  where cdfolhapagamento = rec.cdfolsim and cdvinculo = rec.cdvinculo;
      delete epaghistoricorubricavinculo where cdfolhapagamento = rec.cdfolsim and cdvinculo = rec.cdvinculo;
      delete epaghistoricorubricarelvinc where cdfolhapagamento = rec.cdfolsim and cdvinculo = rec.cdvinculo;
      
      update epagcapahistrubricavinculo  set cdfolhapagamento = rec.cdfolsim where cdfolhapagamento = rec.cdfolnormal and cdvinculo = rec.cdvinculo;
      update epaghistoricorubricavinculo set cdfolhapagamento = rec.cdfolsim where cdfolhapagamento = rec.cdfolnormal and cdvinculo = rec.cdvinculo;
      update epaghistoricorubricarelvinc set cdfolhapagamento = rec.cdfolsim where cdfolhapagamento = rec.cdfolnormal and cdvinculo = rec.cdvinculo;
        
   end loop;
end;

