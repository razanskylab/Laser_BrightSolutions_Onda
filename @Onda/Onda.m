classdef Onda < handle
  % Onda laser fun

  properties % default properties, probaly most of your data
    warmUpTime = 15; % [s], duration over which laser slowly warms up on start
    maxWarmUpPower = Onda.LASING_POWER;
    %% laser info
    power = 0; % [%], equivalent to current, but easier to use.. SET/GET
    trigFreq = 100; % trigger freq. for internal triggering, SET/GET
    comPort = 'COM102'; % com port of diode laser (USB Serial Port in Device managr)
    silenceOutput = false;
  end

  properties (Constant) % can only be changed here in the def file
    TRIG_LIMIT = [0 100000]; % min and max limits of trigger freq.
    LASING_POWER = 40; % power in % at which lasing starts, used for warmup
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
    trigMode; % 0 = internal, 1 = external, 2 = CW. SET/GET
    pdSignal; % not sure what this even is...
    SerialObj = []; % serial port object, required for Matlab to laser comm.
    isConnected = 0; % Connection stored as logical
    isWarmedUp = 0;
    laserError = 0; % error on laser side (warmup, etc...)
    comError = 0; % error during communication
    errorStatus = 'No errors yet...';
    Status; % struct for storing laser status
  end

  % can't be seen or set by user, only by methods in this class
  properties (Hidden=true)
    D = []; % struct to store query answer from laser in dec form
    H = []; % struct to store query answer from laser in hex char form
    hexAnswer; % raw hex answer (excl. CR character)
    outTarget = 1; % 1 for workspace, 2 for standard error, or file id

  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % constructor, desctructor, save obj
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  methods
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % constructor, called when class is created
    function Onda = Onda(doConnect)
      % constructor, called when creating instance of this class
      if nargin > 0
        % doConnect = doConnect
      else
        doConnect = Onda.CONNECT_ON_STARTUP; % use default setting
      end

      % auto connect on creation?
      if doConnect
        fprintf(Onda.outTarget,'[Onda] Hello good sir, connecting to the pew pew machine!\n');
        Onda.Open_Connection();
        Onda.Update_Status(0); % update laser status, only plot warnings
      else
        fprintf(Onda.outTarget,'[Onda] Initialized but not connected yet.\n');
        % warn user that you are not connected yet...
      end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Destructor: Mainly used to close the serial connection correctly
    function delete(Onda)
      % Close Serial connection
      if ~isempty(Onda.SerialObj) && strcmp(Onda.SerialObj.Status,'open')
        fprintf(Onda.outTarget,'[Onda] Closing and cleaning serial connection.\n');
        Onda.Close_Connection();
      end
      fprintf(Onda.outTarget,'[Onda] You destroyed me, you monster!\n');
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % when saved, hand over only properties stored in saveObj
    function SaveObj = saveobj(Onda)
      % only save public properties of the class if you save it to mat file
      % without this saveobj function you will create an error when trying
      % to save this class
      SaveObj.current = Onda.current;
      SaveObj.power = Onda.power;
      % SaveObj.pos = EC.pos;
    end
  end


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% "Standard" methods, i.e. functions which can be called by the user and by
  % the class itself
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  methods
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Emission on
    function On(Onda)
      fprintf(Onda.outTarget,'[Onda] Switching emission on.\n');
      Onda.Update_Status(0);
      if ~Onda.Status.interlock
        short_warn('[Onda] Laser not enabled (big red button)?');
        Onda.Update_Status(0);
        if ~Onda.Status.interlock
          error('[Onda] You need to enable the laser first!');
        else
          fprintf(Onda.outTarget,'[Onda] Looks ok now, just needed to update the status...\n');
        end
      end
      Onda.Query_Command('84010000');
      Onda.emission = 1; % is laser emission on/off?
    end

    % Emission off
    function Off(Onda)
      fprintf(Onda.outTarget,'[Onda] Switching emission off.\n');
      Onda.Query_Command('84000000');
      Onda.emission = 0; % is laser emission on/off?
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Aim beam on
    function Aim_On(Onda)
      fprintf(Onda.outTarget,'[Onda] Switching aim beam on.\n');
      Onda.Query_Command('86010000');
      Onda.aimBeam = 1; % is aim beam on/off?
    end

    % Aim beam off
    function Aim_Off(Onda)
      fprintf(Onda.outTarget,'[Onda] Switching aim beam off.\n');
      Onda.Query_Command('86000000');
      Onda.aimBeam = 0; % is aim beam on/off?
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Property Set functions are down here...
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Must be in this file! Can't be in seperate file in Onda folder
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function set.power(Onda,setPower)
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
      Onda.Query_Command([h p1 p23]); % cs added automatically
      % check that power was set, also update property
      powerHex = [Onda.H.p2 Onda.H.p3];
      Onda.power = 100*hex2dec(powerHex)./maxRange;
      maxAllowError = 0.1; % [in %] 100/1024 ~ 0.1%
      if (setPower-Onda.power) > maxAllowError
        short_warn('Laser power not set correctly!')
      end
      % FIXME read current value here as well and update that!?!
    end

    function power = get.power(Onda)
      h = '88';
      p1 = '00'; % set level in percent relative to max range
      p23 = '0000';
      Onda.Query_Command([h p1 p23]); % cs added automatically
      % check that power was set, also update property
      powerHex = [Onda.H.p2 Onda.H.p3];
      maxRange = hex2dec('FFF'); % 4095
      power = 100*hex2dec(powerHex)./maxRange;
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function current = get.current(Onda)
      Onda.Query_Command('92000000');
      current = Onda.D.p1;
      % FIXME is this relative to 1024 where 1024 is max current???
      raw = hex2dec([Onda.H.p2 Onda.H.p3]);
      % read back current not accurate, convert raw value to more accurate
      % percentage value
      rawRange = Onda.MAX_CURRENT_RAW - Onda.ZERO_CURRENT_RAW;
      raw = raw - Onda.ZERO_CURRENT_RAW; % correct for zero offset
      rawValPercent = raw./rawRange;
      % calculate more accurate current from percentage value
      currentRange = Onda.MAX_CURRENT - Onda.ZERO_CURRENT;
      accuCurrent = Onda.ZERO_CURRENT + currentRange.*rawValPercent;
      % make sure both currents are within reasonable range
      if abs(accuCurrent-current) > 1 % allow for 1A error...
        short_warn('[Onda] Current read-out fishy...')
      else
        current = accuCurrent;
      end
      fprintf(Onda.outTarget,'[Onda] Laser current: %2.1fA (%2.1f%%)\n',current,rawValPercent*100);
    end
    % NOTE no set function for current, laser current is set via power command!


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function current = get.pdSignal(Onda)
      Onda.Query_Command('94000000');
      % FIXME is this relative to 1024 where 1024 is max current???
      raw = hex2dec([Onda.H.p2 Onda.H.p3]);
      fprintf(Onda.outTarget,'[Onda] Photodiode signal: %2.0f?? (%2.1f%%??)\n',raw,raw./2^10*100);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function set.trigFreq(Onda, frequency)
      % set.trigFreq(Onda, frequency)
      % Sets the Pulse Repetition Rate (PRR) to custom values. The PRR [Hz] is a 24 bit
      % parameter specified by p1 + p2 + p3.
      % Header A6h
      % Parameters p1, p2, p3
      % Answer A7h + p1 + p2 + p3
      maxTrigFreq = max(Onda.TRIG_LIMIT);
      minTrigFreq = min(Onda.TRIG_LIMIT);
      if frequency > maxTrigFreq
        fprintf(2,'[ONDA Error] Trigger frequency must be smaller than %2.1fkHz\n',...
          round(maxTrigFreq./1000));
        return;
      end
      if frequency < minTrigFreq
        fprintf(2,'[ONDA Error] Trigger frequency must be larger than %2.1fHz\n',...
          minTrigFreq);
        return;
      end

      trigFreqHex = dec2hex(frequency,6);
      fullCommand = ['A6' trigFreqHex];
      Onda.Query_Command(fullCommand);
    end

    function trigFreq = get.trigFreq(Onda)
      % Reads pulse train frequency (24bit data)
      % Header 9Ah
      % Answer 9Bh + r1 + r2 + r3
      Onda.Query_Command('9A000000');
      trigFreq = hex2dec([Onda.H.p1 Onda.H.p2 Onda.H.p3]);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function set.silenceOutput(Onda, doSilence)
      % set.verboseOutput(Onda, verbose)
      % sets the target of fprintf output to either 1 (screen)
      % or 3 (nothing, unless there is a file open with that ID which I hope
      % there is not...otherwise we write logs there I guess...)
      if doSilence
        Onda.outTarget = 3;
      else
        Onda.outTarget = 1;
      end
    end

  end


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% Private Methods, can only be called from methods in the class itself
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  methods (Access=private)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [] = Send_Command(Onda,command)
      if isempty(Onda.SerialObj) || ~strcmp(Onda.SerialObj.Status,'open')
        Onda.D = [];
        Onda.H = [];
        error('No open serial connection, can''t query!');
      end
      % commands are send as hex string of format
      % header p1 p2 p3 checksum; eg.  80 00 00 00 80
      checkSum = Onda.Get_Hex_Checksum(command);
      fullCommand = [command checkSum];
      query(Onda.SerialObj,fullCommand); % ignore answer, better to query to check
      % for errors
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function Query_Command(Onda,command)
      % Query_Command(Onda,command)
      % Onda laser always replies to commands, so one should always query and
      % check for errors even when just settings things (i.e. current etc)
      if isempty(Onda.SerialObj) || ~strcmp(Onda.SerialObj.Status,'open')
        Onda.D = [];
        Onda.H = [];
        error('No open serial connection, can''t query!');
      end

      % commands are send as hex string of format
      % header p1 p2 p3 checksum; eg.  80 00 00 00 80
      checkSum = Onda.Get_Hex_Checksum(command);
      fullCommand = [command checkSum];
      rawCharAnswer = query(Onda.SerialObj,fullCommand); % ignore answer
      % check for error in response
      Onda.Parse_Answer(rawCharAnswer);
      if  strcmp(Onda.H.header,'E1')
        Onda.laserError = true;
        Onda.Parse_Error();
        fprintf(Onda.outTarget,Onda.errorStatus)
      end
    end
  end

end
