% Open_Connection @ Onda

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = Open_Connection(Obj)
  % open serial connection to laser on comPort, creates serial obj
  % also displays laser status
  tic;
  Obj.VPrintF_With_ID('Openning serial connection...');

  Obj.SerialObj = instrfind('Type', 'serial', 'Port', Obj.comPort);

  % Create the serial port object if it does not exist
  % otherwise use the object that was found.
  if isempty(Obj.SerialObj)
    Obj.SerialObj = serial(Obj.comPort);
  else
    fclose(Obj.SerialObj);
    Obj.SerialObj = Obj.SerialObj(1);
  end

  % setup serial connection correctly
  set(Obj.SerialObj, 'BaudRate', Obj.BAUD_RATE);
  set(Obj.SerialObj, 'Terminator',Obj.TERMINATOR);
  set(Obj.SerialObj, 'Timeout', Obj.TIME_OUT);
  set(Obj.SerialObj, 'DataTerminalReady', 'off');
  set(Obj.SerialObj, 'RequestToSend', 'off');

  fopen(Obj.SerialObj); % Connect to laser
  Obj.Done();
  Obj.Check_Serial_Connection();
end
