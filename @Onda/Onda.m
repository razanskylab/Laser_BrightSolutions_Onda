classdef Onda < BaseHardwareClass

  properties % default properties, probaly most of your data
    warmUpTime = 15; % [s], duration over which laser slowly warms up on start
    maxWarmUpPower = Onda.LASING_POWER;
    %% laser info
    power = 0; % [%], equivalent to current, but easier to use.. SET/GET
    trigFreq = 100; % trigger freq. for internal triggering, SET/GET
    comPort = 'COM4'; % com port of diode laser (USB Serial Port in Device managr)
    classId = '[Laser]'; % used for Obj.VPrintF_With_ID_W   
    trigMode; % 0 = internal, 1 = external, 2 = CW. SET/GET
  end

  properties (Constant) % can only be changed here in the def file
    TRIG_LIMIT = [0 100000]; % min and max limits of trigger freq.
    LASING_POWER = 35; % power in % at which lasing starts, used for warmup
    ZERO_CURRENT = 20; % [A]
    ZERO_CURRENT_RAW = 537; % (raw value, equal to 20A)
    MAX_CURRENT = 41; %  [A]
    MAX_CURRENT_RAW = 761; %  raw value, read back from laser
  end

  properties (Constant,Hidden=true) % can only be changed here in the def file
    WARM_UP_INTERVAL = 1; %[s], interval in which laser current is increased
    CONNECT_ON_STARTUP = true;
    BAUD_RATE = 9600;  % BaudRate as bits per second
    TERMINATOR = 'CR'; % carriage return + linefeed termination
    TIME_OUT = 2 ; %[s], serial port communication timenout
    SERIAL_NUMBER = 'ABC'; %used to check connection to correct device, i.e. laser
  end

  properties (Dependent) %callulated based on other values

  end

  properties (GetAccess=private) % can't be seen but can be set by user
  end

  properties (SetAccess=private) % can be seen but not set by user
    current; % [A], diode laser current, only readable, laser power set in percent
    emission; % is laser emission on/off?
    aimBeam; % is aim beam on/off?
    pdSignal; % not sure what this even is...
    SerialObj = []; % serial port object, required for Matlab to laser comm.
    isConnected = 0; % Connection stored as logical
    isWarmedUp = 0;
    laserError = 0; % error on laser side (warmup, etc...)
    comError = 0; % error during communication
    errorStatus = 'No errors yet...';
    Status; % struct for storing laser status
    interlockStatus; % true = laser is on, i.e. button is pressed
  end

  % can't be seen or set by user, only by methods in this class
  properties (Hidden=true)
    D = []; % struct to store query answer from laser in dec form
    H = []; % struct to store query answer from laser in hex char form
    hexAnswer; % raw hex answer (excl. CR character)
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % constructor, desctructor, save obj
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  methods
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % constructor, called when class is created
    function Obj = Onda(varargin)
      if nargin < 1
        doConnect = Obj.DO_AUTO_CONNECT;
        Obj.Serial = [];
      end

      if (nargin >= 1)
        doConnect = varargin{1};
      end

      if (nargin >= 2)
        Obj.comPort = varargin{2};
      end

      % auto connect on creation?
      if doConnect
        Obj.VPrintF_With_ID('Connecting to laser!\n');
        Obj.Open_Connection();
        Obj.Update_Status(0); % update laser status, only plot warnings
      else
        Obj.VPrintF_With_ID('Initialized but not connected yet.\n');
        % warn user that you are not connected yet...
      end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Destructor: Mainly used to close the serial connection correctly
    function delete(Obj)
      % Close Serial connection
      if ~isempty(Obj.SerialObj) && strcmp(Obj.SerialObj.Status,'open')
        Obj.VPrintF_With_ID('Closing and cleaning serial connection.\n');
        Obj.Close_Connection();
      end
      Obj.VPrintF_With_ID('You destroyed me, you monster!\n');
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % when saved, hand over only properties stored in saveObj
    function SaveObj = saveobj(Obj)
      SaveObj.current = Obj.current;
      SaveObj.power = Obj.power;
    end
  end


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% "Standard" methods, i.e. functions which can be called by the user and by
  % the class itself
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  methods
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Emission on
    function On(Obj)
      Obj.VPrintF_With_ID('Switching emission on.\n');
      Obj.Update_Status(0);
      if ~Obj.Status.interlock
        short_warn('[Onda] Laser not enabled (big red button)?');
        Obj.Update_Status(0);
        if ~Obj.Status.interlock
          error('[Onda] You need to enable the laser first!');
        else
          Obj.VPrintF_With_ID('Looks ok now, just needed to update the status...\n');
        end
      end
      Obj.Query_Command('84010000');
      Obj.emission = 1; % is laser emission on/off?
    end

    % Emission off
    function Off(Obj)
      Obj.VPrintF_With_ID('Switching emission off.\n');
      Obj.Query_Command('84000000');
      Obj.emission = 0; % is laser emission on/off?
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Aim beam on
    function Aim_On(Obj)
      Obj.VPrintF_With_ID('Switching aim beam on.\n');
      Obj.Query_Command('86010000');
      Obj.aimBeam = 1; % is aim beam on/off?
    end

    % Aim beam off
    function Aim_Off(Obj)
      Obj.VPrintF_With_ID('Switching aim beam off.\n');
      Obj.Query_Command('86000000');
      Obj.aimBeam = 0; % is aim beam on/off?
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Property Set functions are down here...
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Must be in this file! Can't be in seperate file in Onda folder
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function set.power(Obj,setPower)
      if ((setPower > 100) || (setPower < 0)) && ~isinf(setPower)
        short_warn('Laser power must be 0<= power <=100%!');
        short_warn('Laser power was not set!');
        return;
      elseif (setPower > 0) && (setPower < 1)
        warnStr = sprintf('Laser power should be in 0-100%% range! Multiply by 100?\n');
        warnStr = [warnStr sprintf('         Not doing this automatically for safety concerns!')];
        short_warn(warnStr);
        short_warn('Laser power was not set!');
        return;
      elseif isinf(setPower)
        % little trick where we don't change the power when we set it to inf
        return;
      end
      maxRange = hex2dec('FFF'); % 4095
      setVal = round((setPower./100)*maxRange);
      hexVal = dec2hex(setVal,4);
      h = '88';
      p1 = '03'; % set level in percent relative to max range
      p23 = hexVal;
      Obj.Query_Command([h p1 p23]); % cs added automatically
      % check that power was set, also update property
      powerHex = [Obj.H.p2 Obj.H.p3];
      Obj.power = 100*hex2dec(powerHex)./maxRange;
      maxAllowError = 0.1; % [in %] 100/1024 ~ 0.1%
      if (setPower-Obj.power) > maxAllowError
        short_warn('Laser power not set correctly!')
      end
      % FIXME read current value here as well and update that!?!
    end

    function power = get.power(Obj)
      h = '88';
      p1 = '00'; % set level in percent relative to max range
      p23 = '0000';
      Obj.Query_Command([h p1 p23]); % cs added automatically
      % check that power was set, also update property
      powerHex = [Obj.H.p2 Obj.H.p3];
      maxRange = hex2dec('FFF'); % 4095
      power = 100*hex2dec(powerHex)./maxRange;
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function current = get.current(Obj)
      Obj.Query_Command('92000000');
      current = Obj.D.p1;
      % FIXME is this relative to 1024 where 1024 is max current???
      raw = hex2dec([Obj.H.p2 Obj.H.p3]);
      % read back current not accurate, convert raw value to more accurate
      % percentage value
      rawRange = Obj.MAX_CURRENT_RAW - Obj.ZERO_CURRENT_RAW;
      raw = raw - Obj.ZERO_CURRENT_RAW; % correct for zero offset
      rawValPercent = raw./rawRange;
      % calculate more accurate current from percentage value
      currentRange = Obj.MAX_CURRENT - Obj.ZERO_CURRENT;
      accuCurrent = Obj.ZERO_CURRENT + currentRange.*rawValPercent;
      % make sure both currents are within reasonable range
      if abs(accuCurrent-current) > 1 % allow for 1A error...
        short_warn('[Onda] Current read-out fishy...')
      else
        current = accuCurrent;
      end
      Obj.VPrintF_With_ID('Laser current: %2.1fA (%2.1f%%)\n',current,rawValPercent*100);
    end
    % NOTE no set function for current, laser current is set via power command!

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function raw = get.pdSignal(Obj)
      Obj.Query_Command('94000000');
      % FIXME is this relative to 1024 where 1024 is max current???
      raw = hex2dec([Obj.H.p2 Obj.H.p3]);
      infoStr = sprintf('Photodiode signal: %2.0f?? (%2.1f ??)\n',raw,raw./2^10*100);
      Obj.VPrintF_With_ID(infoStr);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function set.trigFreq(Obj, frequency)
      % set.trigFreq(Obj, frequency)
      % Sets the Pulse Repetition Rate (PRR) to custom values. The PRR [Hz] is a 24 bit
      % parameter specified by p1 + p2 + p3.
      % Header A6h
      % Parameters p1, p2, p3
      % Answer A7h + p1 + p2 + p3
      maxTrigFreq = max(Obj.TRIG_LIMIT);
      minTrigFreq = min(Obj.TRIG_LIMIT);
      if frequency > maxTrigFreq
        fprintf(2,'[Error] Trigger frequency must be smaller than %2.1fkHz\n',...
          round(maxTrigFreq./1000));
        return;
      end
      if frequency < minTrigFreq
        fprintf(2,'[Error] Trigger frequency must be larger than %2.1fHz\n',...
          minTrigFreq);
        return;
      end

      trigFreqHex = dec2hex(frequency,6);
      fullCommand = ['A6' trigFreqHex];
      Obj.Query_Command(fullCommand);
    end

    function trigFreq = get.trigFreq(Obj)
      % Reads pulse train frequency (24bit data)
      % Header 9Ah
      % Answer 9Bh + r1 + r2 + r3
      Obj.Query_Command('9A000000');
      trigFreq = hex2dec([Obj.H.p1 Obj.H.p2 Obj.H.p3]);
    end

  end


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% Private Methods, can only be called from methods in the class itself
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  methods (Access=private)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [] = Send_Command(Obj,command)
      if isempty(Obj.SerialObj) || ~strcmp(Obj.SerialObj.Status,'open')
        Obj.D = [];
        Obj.H = [];
        error('No open serial connection, can''t query!');
      end
      % commands are send as hex string of format
      % header p1 p2 p3 checksum; eg.  80 00 00 00 80
      checkSum = Obj.Get_Hex_Checksum(command);
      fullCommand = [command checkSum];
      query(Obj.SerialObj,fullCommand); % ignore answer, better to query to check
      % for errors
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function Query_Command(Obj,command)
      % Query_Command(Obj,command)
      % Onda laser always replies to commands, so one should always query and
      % check for errors even when just settings things (i.e. current etc)
      if isempty(Obj.SerialObj) || ~strcmp(Obj.SerialObj.Status,'open')
        Obj.D = [];
        Obj.H = [];
        error('No open serial connection, can''t query!');
      end

      % commands are send as hex string of format
      % header p1 p2 p3 checksum; eg.  80 00 00 00 80
      checkSum = Obj.Get_Hex_Checksum(command);
      fullCommand = [command checkSum];
      rawCharAnswer = query(Obj.SerialObj,fullCommand); % ignore answer
      % check for error in response
      Obj.Parse_Answer(rawCharAnswer);
      if  strcmp(Obj.H.header,'E1')
        Obj.laserError = true;
        Obj.Parse_Error();
        fprintf(2,Obj.errorStatus);
      end
    end
  end

end
