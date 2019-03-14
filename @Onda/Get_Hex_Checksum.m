function [hexCheckSum,decCheckSum] = Get_Hex_Checksum(O,hexStr)
  % also called CheckSum8 Xor?
  % check results at
  % https://www.scadacore.com/tools/programming-calculators/online-checksum-calculator/#

  decCheckSum = 0;
  for iChar = 1:2:length(hexStr)
    hex = hexStr(iChar:iChar+1); % get first hex number in hex format
    dec = hex2dec(hex); % convert to decimal number
    decCheckSum = bitxor(decCheckSum,dec); % bitwise xor through all hex numbers
  end
  hexCheckSum = dec2hex(decCheckSum,2);
end

% for iChar = 1:2:length(hexStr)
%   hex = hexStr(iChar:iChar+1);
%   dec = hex2dec(hex);
%   lrc1 = bitget(lrc,8:-1:1)
%   lrc = bitxor(lrc,dec);
%   dec1 = bitget(dec,8:-1:1)
%   lrc1 = bitget(lrc,8:-1:1)
%   fprintf('hex: %s(%i) |lrc (%s)%i\n',hex,dec,dec2hex(lrc),lrc);
%   % char2 = hexStr(iChar+1);
%   % b1 = bitget(b,8:-1:1);
% end
% for iChar = 1:length(hexStr)
%   hex = hexStr(iChar);
%   dec = hex2dec(hex);
%   lrc1 = bitget(lrc,8:-1:1)
%   lrc = bitxor(lrc,dec);
%   dec1 = bitget(dec,8:-1:1)
%   lrc1 = bitget(lrc,8:-1:1)
%   fprintf('hex: %s dec: %i lrc %i\n',hex,dec,lrc);
%   % char2 = hexStr(iChar+1);
%   % b1 = bitget(b,8:-1:1);
% end
