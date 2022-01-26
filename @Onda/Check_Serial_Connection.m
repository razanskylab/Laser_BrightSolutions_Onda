% File: Check_Serial_Connection.m @ Onda
% Date: 26.04.2021

function isConnected = Check_Serial_Connection(Onda)
  fprintf(Onda.outTarget,'[Onda] Checking laser connection: ');

  if isempty(Onda.SerialObj)
    fprintf(Onda.outTarget,' No laser connection established!\n');
    return;
  else % serial connection exists
    Onda.Query_Command('80000000');
    if ~Onda.D.p1 && ~Onda.D.p2 && ~Onda.D.p3
      Onda.isConnected = true;
      fprintf(Onda.outTarget,' Laser connection established!\n');
    else
      Onda.isConnected = false;
      fprintf(Onda.outTarget,' Could not establish connection to laser!\n');
    end
  end
end
