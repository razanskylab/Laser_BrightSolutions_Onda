function [D,H,comError] = Parse_Answer(Onda,rawCharAnswer,verboseOut)

  if nargin < 3
    verboseOut = 0;
  end

  % rawCharAnswer format:
  % header p1 p2 p3 checksum
  Onda.comError = false;
  returnChar = char(13);
  if strcmp(rawCharAnswer(end),returnChar)
    rawCharAnswer = rawCharAnswer(1:end-1); % crop away CR character
  else
    Onda.comError = true;
    Onda.errorStatus = 'ComError: No termination (CR) found!';
    short_warn(Onda.errorStatus);
    return;
  end

  % get seperate parts of answer string
  H.header = rawCharAnswer(1:2);
  H.p1 = rawCharAnswer(3:4);
  H.p2 = rawCharAnswer(5:6);
  H.p3 = rawCharAnswer(7:8);
  H.checkSum = rawCharAnswer(9:10);

  if verboseOut
    fprintf(Onda.outTarget,'rawAnswer: %s\n',rawCharAnswer);
    fprintf(Onda.outTarget,'h=%sh\tp1=%sh\tp2=%sh\tp3=%sh\tCS=%sh\n',...
      H.header,H.p1,H.p2,H.p3,H.checkSum);
  end

  % convert hex to numbers for easier processing
  D.header = hex2dec(H.header);
  D.p1 = hex2dec(H.p1);
  D.p2 = hex2dec(H.p2);
  D.p3 = hex2dec(H.p3);
  D.checkSum = hex2dec(H.checkSum);

  if verboseOut
    fprintf(Onda.outTarget,'h=%2.0f\tp1=%2.0f\tp2=%2.0f\tp3=%2.0f\tCS=%2.0f\n',...
      D.header,D.p1,D.p2,D.p3,D.checkSum);
  end

  % check for correct checkSum
  Onda.hexAnswer = [H.header H.p1 H.p2 H.p3];
  commandSum = Onda.Get_Hex_Checksum(Onda.hexAnswer);
  if ~strcmp(commandSum,H.checkSum)
    Onda.comError = true;
    Onda.errorStatus = 'ComError: Check sum error in recieved answer!';
    short_warn(Onda.errorStatus);
  end
  % store the raw answers for error checking, processing and debugging
  Onda.D = D;
  Onda.H = H;
end
