clear all; rehash path;
O = Onda;
O.Update_Status();
O.verboseOutput = true; % enable / disable output to workspace

O.On; % enable emission
O.Off; % disable emission
O.Aim_On; % enable aim beam
O.Aim_Off; % disable aim beam
O.Set_Trigger_Source(0); % 0 = internal trigger, 1 = external trigger source

% get important laser info
laserPower = O.power; % read laser power in %
laserCurrent = O.current; % read laser current in A
laserFreq = O.trigFreq;

% set important laser parameters
O.power = 40; % set laser power in %
O.trigFreq = 1000; % set trigger frequency of laser when internally triggering

O.Warm_Up();
