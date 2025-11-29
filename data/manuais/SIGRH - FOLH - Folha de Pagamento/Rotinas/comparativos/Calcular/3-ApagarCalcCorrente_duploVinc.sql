begin
   for rec in (select cdfolhapagamento, cdvinculo
                 from tmpxpes) LOOP
  
       delete epaghistoricorubricarelvinc
        where cdfolhapagamento = rec.cdfolhapagamento
          and cdvinculo = rec.cdvinculo;
          
       delete epaghistoricorubricavinculo
        where cdfolhapagamento = rec.cdfolhapagamento
          and cdvinculo = rec.cdvinculo;

       delete epagcapahistrubricavinculo
        where cdfolhapagamento = rec.cdfolhapagamento
          and cdvinculo = rec.cdvinculo;
                       
   end loop;
   commit;
end;                
                 
         
