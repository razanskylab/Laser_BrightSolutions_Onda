% [] = Warm_Up(Onda, doCoolDown, warmUpTime, maxWarmUpPower)
% connect, check for errors, turn on Onda and slowly increase current
% Uses default time and current values if none are given
% Performs cool down from current Onda current value if doCoolDown=1
% trigger mode for warm up is internal, for cool down external, the
% trigger modes present in the Onda at the time of warmUp/coolDown
% are restored afterwards.

% is located, kinda like include in C...

function [] = Warm_Up(Onda, doCoolDown, warmUpTime, maxWarmUpPower)

   if nargin > 2 % replace default warum up values
      Onda.warmUpTime = warmUpTime;  % warmUpTime [min]
      Onda.maxWarmUpPower = maxWarmUpPower; % [A]
   elseif nargin <= 1
      doCoolDown = 0; % don't cool down per default
   end

   Onda.Update_Status(0); %make sure all is good before warming up

   % calc steps and current values based on time and nSteps
   if ~doCoolDown % do warm up, i.e. don't do cool down duh
      if (Onda.power >= Onda.maxWarmUpPower-2)
         fprintf(['[Onda] Laser power (%2.1f%%) already at or above warmUpPower ('...
            '%2.1f A)!\n'],Onda.power,Onda.maxWarmUpPower);
         short_warn('[Onda] WarmUp cancled');
         return;
      end
      nWarmUpSteps = Onda.warmUpTime/Onda.WARM_UP_INTERVAL;
      powerStepSize = Onda.maxWarmUpPower/nWarmUpSteps;
      % warm up from present current setting in Onda
      powerSteps = Onda.power:powerStepSize:Onda.maxWarmUpPower;
      powerSteps = round(powerSteps*10)/10; %round to one digit
      fprintf('[Onda] Warming Up Laser to %2.1f%%\n',Onda.maxWarmUpPower);
      fprintf('[Onda] Laser will go pew pew, and so should you!\n');
      Onda.Set_Trigger_Source(0); %set to internal trigger mode
      Onda.On();
    else
      % cool down can be faster, given by Onda.CoolDownFactor
      nWarmUpSteps = Onda.warmUpTime/Onda.WARM_UP_INTERVAL;
      powerStepSize = Onda.power/nWarmUpSteps;
      powerSteps = Onda.power:-powerStepSize:0;
      powerSteps = round(powerSteps*10)/10; %round to one digit
      fprintf('[Onda] Cooling down Onda.');
   end

   % prepare workspace waitbar
   cpb = ConsoleProgressBar();
   cpb.setLeftMargin(0);
   cpb.setTopMargin(0);
   cpb.setLength(30);
   cpb.setMinimum(1);
   cpb.setMaximum(length(powerSteps));
   cpb.setElapsedTimeVisible(1);
   cpb.setRemainedTimeVisible(1);
   cpb.setElapsedTimePosition('left');
   cpb.setRemainedTimePosition('right');
   cpb.start();
   % start while loop that steps up/down the Onda current
   iStep = 1;
   tic;

   while (iStep <= length(powerSteps))
     % set new Onda current if WARM_UP_INTERVAL passed
     if (toc > Onda.WARM_UP_INTERVAL)
        currentPower = powerSteps(iStep); % only read once
        Onda.power = currentPower;
        dispText = sprintf('%2.1f%%/%2.1f%%',currentPower, Onda.maxWarmUpPower);
        cpb.setValue(iStep);
        cpb.setText(dispText);
        tic;
        iStep = iStep + 1;
     end
   end
   cpb.stop();

   if ~doCoolDown % we warmed up the Onda
      Onda.isWarmedUp = 1;
      fprintf('[Onda] Laser warm up successful. \n')
   else
      Onda.isWarmedUp = 0;
      fprintf('[Onda] Laser cool down successful. \n')
   end

   Onda.Set_Trigger_Source(1); %set to internal trigger mode

   % play a fun sound
   load gong.mat;
   y = y(3000:30000);
   sound([y;y;y], 10*Fs);
   clear Fs y;
end
