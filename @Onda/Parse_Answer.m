function [D,H,comError] = Parse_Answer(Obj,rawCharAnswer,verboseOut)

  if nargin < 3
    verboseOut = 0;
  end

  % rawCharAnswer format:
  % header p1 p2 p3 checksum
  Obj.comError = false;
  returnChar = char(13);
  if strcmp(rawCharAnswer(end),returnChar)
    rawCharAnswer = rawCharAnswer(1:end-1); % crop away CR character
  else
    Obj.comError = true;
    Obj.errorStatus = 'ComError: No termination (CR) found!';
    short_warn(Obj.errorStatus);
    return;
  end

  % get seperate parts of answer string
  H.header = rawCharAnswer(1:2);
  H.p1 = rawCharAnswer(3:4);
  H.p2 = rawCharAnswer(5:6);
  H.p3 = rawCharAnswer(7:8);
  H.checkSum = rawCharAnswer(9:10);

  if verboseOut
    fprintf(Obj.outTarget,'rawAnswer: %s\n',rawCharAnswer);
    fprintf(Obj.outTarget,'h=%sh\tp1=%sh\tp2=%sh\tp3=%sh\tCS=%sh\n',...
      H.header,H.p1,H.p2,H.p3,H.checkSum);
  end

  % convert hex to numbers for easier processing
  D.header = hex2dec(H.header);
  D.p1 = hex2dec(H.p1);
  D.p2 = hex2dec(H.p2);
  D.p3 = hex2dec(H.p3);
  D.checkSum = hex2dec(H.checkSum);

  if verboseOut
    fprintf(Obj.outTarget,'h=%2.0f\tp1=%2.0f\tp2=%2.0f\tp3=%2.0f\tCS=%2.0f\n',...
      D.header,D.p1,D.p2,D.p3,D.checkSum);
  end

  % check for correct checkSum
  Obj.hexAnswer = [H.header H.p1 H.p2 H.p3];
  commandSum = Obj.Get_Hex_Checksum(Obj.hexAnswer);
  if ~strcmp(commandSum,H.checkSum)
    Obj.comError = true;
    Obj.errorStatus = 'ComError: Check sum error in recieved answer!';
    short_warn(Obj.errorStatus);
  end
  % store the raw answers for error checking, processing and debugging
  Obj.D = D;
  Obj.H = H;
end
