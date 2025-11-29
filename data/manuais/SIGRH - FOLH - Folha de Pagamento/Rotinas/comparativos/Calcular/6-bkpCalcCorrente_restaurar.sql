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

-- copiar bkp para folha corrente

declare
  vcapa    EPAGCAPAHISTRUBRICAVINCULO%ROWTYPE;
  vhrv     EPAGHISTORICORUBRICAVINCULO%ROWTYPE;
  vrelvinc EPAGHISTORICORUBRICARELVINC%ROWTYPE;
  
begin
   for rec in (select distinct hrv.cdvinculo,
                               hrv.cdfolhapagamento,
                               cdfolnormal,
                               cdfolsim
                 from tmpxpes hrv
                 
                inner join tmpxdpfolha fp
                  on fp.cdfolhapagamento = hrv.cdfolhapagamento
                  
                  ) loop

      FOR i IN (SELECT * FROM tmpbkphrv where cdvinculo = rec.cdvinculo and cdfolhapagamento = rec.cdfolhapagamento) LOOP
         vhrv := i;
         vhrv.CdFolhaPagamento := rec.cdfolnormal;
         INSERT INTO epaghistoricorubricavinculo values vhrv;
      END LOOP;

      FOR i IN (SELECT * FROM tmpbkprelvinc  where cdvinculo = rec.cdvinculo and cdfolhapagamento = rec.cdfolhapagamento) LOOP
         vrelvinc := i;
         vrelvinc.CdFolhaPagamento := rec.cdfolnormal;
         INSERT INTO epaghistoricorubricarelvinc values vrelvinc;
      END LOOP;
      
      FOR i IN (SELECT * FROM tmpbkpcapa  where cdvinculo = rec.cdvinculo and cdfolhapagamento = rec.cdfolhapagamento) LOOP
         vcapa := i;
         vcapa.CdFolhaPagamento := rec.cdfolnormal;
         vcapa.vlcredito := null;
         INSERT INTO epagcapahistrubricavinculo 
              (cdfolhapagamento, 
               cdvinculo, 
               vlproventos, 
               vldescontos, 
               cdmotivoafasttemporario, 
               cdmotivoafastdefinitivo, 
               insistemaorigem, 
               flativo, 
               flpagamentobloqueado, 
               flrecadastrado, 
               cdcreditobancario, 
               cdrelacaotrabalho, 
               cdregimetrabalho, 
               nucho, 
               cdgrupoocupacional, 
               cdlocalidade, 
               cdvalorgeralcefagrup, 
               cdcargocomissionado, 
               nunivelcef, 
               nureferenciacef, 
               nureferenciacco, 
               nunivelcco, 
               cdestruturacarreira, 
               cdgrauescolaridade, 
               cdnaturezavinculo, 
               cdsituacaoprevidenciaria, 
               nuchorelacao, 
               cdunidadeorganizacional, 
               cdagenciacredito, 
               nucontacredito, 
               nudvcontacredito, 
               cdagenciareceb, 
               nucontareceb, 
               fltipocontacredito, 
               nuagencia, 
               nudvagencia, 
               nubanco, 
               flbloqueioenviado, 
               cdorgaointerno, 
               cdorgaoexterno, 
               cdcentrocusto, 
               inaposentadoriaespecial, 
               cdorgaoorigempensionista, 
               nuordemcalculo, 
               vlpercentcontribindiv)           
         
         values 
              (vcapa.cdfolhapagamento, 
               vcapa.cdvinculo, 
               vcapa.vlproventos, 
               vcapa.vldescontos, 
               vcapa.cdmotivoafasttemporario, 
               vcapa.cdmotivoafastdefinitivo, 
               vcapa.insistemaorigem, 
               vcapa.flativo, 
               vcapa.flpagamentobloqueado, 
               vcapa.flrecadastrado, 
               vcapa.cdcreditobancario, 
               vcapa.cdrelacaotrabalho, 
               vcapa.cdregimetrabalho, 
               vcapa.nucho, 
               vcapa.cdgrupoocupacional, 
               vcapa.cdlocalidade, 
               vcapa.cdvalorgeralcefagrup, 
               vcapa.cdcargocomissionado, 
               vcapa.nunivelcef, 
               vcapa.nureferenciacef, 
               vcapa.nureferenciacco, 
               vcapa.nunivelcco, 
               vcapa.cdestruturacarreira, 
               vcapa.cdgrauescolaridade, 
               vcapa.cdnaturezavinculo, 
               vcapa.cdsituacaoprevidenciaria, 
               vcapa.nuchorelacao, 
               vcapa.cdunidadeorganizacional, 
               vcapa.cdagenciacredito, 
               vcapa.nucontacredito, 
               vcapa.nudvcontacredito, 
               vcapa.cdagenciareceb, 
               vcapa.nucontareceb, 
               vcapa.fltipocontacredito, 
               vcapa.nuagencia, 
               vcapa.nudvagencia, 
               vcapa.nubanco, 
               vcapa.flbloqueioenviado, 
               vcapa.cdorgaointerno, 
               vcapa.cdorgaoexterno, 
               vcapa.cdcentrocusto, 
               vcapa.inaposentadoriaespecial, 
               vcapa.cdorgaoorigempensionista, 
               vcapa.nuordemcalculo, 
               vcapa.vlpercentcontribindiv) ;
               
      END LOOP;         

   end loop;
end;

