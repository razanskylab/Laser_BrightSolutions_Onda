% Open_Connection @ Onda

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = Open_Connection(Onda)
   % open serial connection to laser on comPort, creates serial obj
   % also displays laser status
  fprintf(Onda.outTarget,'[Onda] Openning serial connection...');

  Onda.SerialObj = instrfind('Type', 'serial', 'Port', Onda.comPort);

  % Create the serial port object if it does not exist
  % otherwise use the object that was found.
  if isempty(Onda.SerialObj)
    Onda.SerialObj = serial(Onda.comPort);
  else
    fclose(Onda.SerialObj);
    Onda.SerialObj = Onda.SerialObj(1);
  end

  % setup serial connection correctly
  set(Onda.SerialObj, 'BaudRate', Onda.BAUD_RATE);
  set(Onda.SerialObj, 'Terminator',Onda.TERMINATOR);
  set(Onda.SerialObj, 'Timeout', Onda.TIME_OUT);
  set(Onda.SerialObj, 'DataTerminalReady', 'off');
  set(Onda.SerialObj, 'RequestToSend', 'off');

  fopen(Onda.SerialObj); % Connect to laser
  fprintf(Onda.outTarget,'done.\n');
  Onda.Check_Serial_Connection();
end
