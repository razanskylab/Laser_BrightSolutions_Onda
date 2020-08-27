function Check_Serial_Connection(Obj)
  Obj.VPrintF_With_ID('Checking laser connection:\n');
  if isempty(Obj.SerialObj)
    Obj.VPrintF_With_ID('No laser connection established!\n');
    return;
  else % serial connection exists
    Obj.Query_Command('80000000');
    if ~Obj.D.p1 && ~Obj.D.p2 && ~Obj.D.p3
      Obj.isConnected = true;
      Obj.VPrintF_With_ID('Laser connection established!\n');
    else
      Obj.isConnected = false;
      Obj.VPrintF_With_ID('Could not establish connection to laser!\n');
    end
  end
end
