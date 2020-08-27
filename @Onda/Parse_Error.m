function [] = Parse_Error(Obj)
  %  Parse_Error(Onda)
  % not sure if multiple errors can occur at the same time
  % but this way we are on the save side...
  % not sure
  errorMessage = '';
  if bitget(Obj.D.p1,1)
    errorMessage = [errorMessage 'CR at wrong position\n'];
  end
  if bitget(Obj.D.p1,2)
    errorMessage = [errorMessage 'Message too long\n'];
  end
  if bitget(Obj.D.p1,3)
    errorMessage = [errorMessage 'Checksum error\n'];
  end
  if bitget(Obj.D.p1,4)
    errorMessage = [errorMessage 'Unknown header\n'];
  end
  if bitget(Obj.D.p1,5)
    errorMessage = [errorMessage 'Command syntax error\n'];
  end
  if bitget(Obj.D.p1,6)
    errorMessage = [errorMessage 'Hardware error\n'];
  end
  short_warn('Laser error occured!');
  Obj.errorStatus = errorMessage;
end
