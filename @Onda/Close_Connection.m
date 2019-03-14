function [] = Close_Connection(Onda)
   % close serial connection to Onda, delete SerialObj
   fclose(Onda.SerialObj);  % always, always want to close serial connection
   delete(Onda.SerialObj);
   fprintf(Onda.outTarget,'[Onda] Connection closed.\n');
   Onda.SerialObj = [];
end
