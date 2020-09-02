% [] = Warm_Up(Onda, doCoolDown, warmUpTime, maxWarmUpPower)
% connect, check for errors, turn on Onda and slowly increase current
% Uses default time and current values if none are given
% Performs cool down from current Onda current value if doCoolDown=1
% trigger mode for warm up is internal, for cool down external, the
% trigger modes present in the Onda at the time of warmUp/coolDown
% are restored afterwards.

% is located, kinda like include in C...

function [] = Warm_Up(Obj, doCoolDown, warmUpTime, maxWarmUpPower)

   if nargin > 2 % replace default warum up values
      Obj.warmUpTime = warmUpTime;  % warmUpTime [min]
      Obj.maxWarmUpPower = maxWarmUpPower; % [A]
   elseif nargin <= 1
      doCoolDown = 0; % don't cool down per default
   end

   Obj.Update_Status(0); %make sure all is good before warming up

   % calc steps and current values based on time and nSteps
   if ~doCoolDown % do warm up, i.e. don't do cool down duh
      if (Obj.power >= Obj.maxWarmUpPower-2)
         fprintf(['[Onda] Laser power (%2.1f%%) already at warm up power ('...
            '%2.1f%%)!\n'],Obj.power,Obj.maxWarmUpPower);
         short_warn('   WarmUp cancled');
         return;
      end
      nWarmUpSteps = Obj.warmUpTime/Obj.WARM_UP_INTERVAL;
      powerStepSize = Obj.maxWarmUpPower/nWarmUpSteps;
      % warm up from present current setting in Onda
      powerSteps = Obj.power:powerStepSize:Obj.maxWarmUpPower;
      powerSteps = round(powerSteps*10)/10; %round to one digit
      infoStr = sprintf('   Warming Up Laser to %2.1f Per.\n',Obj.maxWarmUpPower);
      Obj.VPrintF_With_ID(infoStr);
      Obj.trigFreq = 200;
      Obj.Set_Trigger_Source(0); %set to internal trigger mode
      Obj.On();
    else
      % cool down can be faster, given by Obj.CoolDownFactor
      nWarmUpSteps = Obj.warmUpTime/Obj.WARM_UP_INTERVAL;
      powerStepSize = Obj.power/nWarmUpSteps;
      powerSteps = Obj.power:-powerStepSize:0;
      powerSteps = round(powerSteps*10)/10; %round to one digit
      Obj.VPrintF_With_ID('Cooling down...\n');
   end

   progressbar('Laser warm up'); % Init single bar
   iStep = 1;
   lastUpdate = tic;

   while (iStep <= length(powerSteps))
     % set new Onda current if WARM_UP_INTERVAL passed
     if (toc(lastUpdate) > Obj.WARM_UP_INTERVAL)
        currentPower = powerSteps(iStep); % only read once
        Obj.power = currentPower;
        progressbar(iStep./numel(powerSteps));
        iStep = iStep + 1;
        lastUpdate = tic;
     end
   end
   progressbar(1);

   if ~doCoolDown % we warmed up the Onda
      Obj.isWarmedUp = 1;
      Obj.VPrintF_With_ID('Laser warm up successful.\n')
   else
      Obj.isWarmedUp = 0;
      Obj.VPrintF_With_ID('Laser cool down successful.\n')
   end

   Obj.Set_Trigger_Source(1); %set to internal trigger mode
end
