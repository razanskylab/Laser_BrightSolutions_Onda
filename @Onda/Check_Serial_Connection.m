function isConnected = Check_Serial_Connection(Onda)
  fprintf(Onda.outTarget,'[Onda] Checking laser connection:\n');
  if isempty(Onda.SerialObj)
    fprintf(Onda.outTarget,'[Onda] No laser connection established!\n');
    return;
  else % serial connection exists
    Onda.Query_Command('80000000');
    if ~Onda.D.p1 && ~Onda.D.p2 && ~Onda.D.p3
      Onda.isConnected = true;
      fprintf(Onda.outTarget,'[Onda] Laser connection established!\n');
    else
      Onda.isConnected = false;
      fprintf(Onda.outTarget,'[Onda] Could not establish connection to laser!\n');
    end
  end
end
