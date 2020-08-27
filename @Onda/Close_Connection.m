function [] = Close_Connection(Obj)
   % close serial connection to Onda, delete SerialObj
   fclose(Obj.SerialObj);  % always, always want to close serial connection
   delete(Obj.SerialObj);
   Obj.VPrintF_With_ID('Connection closed.\n');
   Obj.SerialObj = [];
end
