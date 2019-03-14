% Update status
function Update_Status(Onda,printStatus)
  if nargin < 2
    printStatus = 1;
  end
  fprintf(Onda.outTarget,'[Onda] Updating laser status.\n');
  Onda.Query_Command('90000000');
  % laser emission status etc
  Onda.trigMode = bitget(Onda.D.p1,1);
  Onda.aimBeam = bitget(Onda.D.p1,3);
  Onda.emission = bitget(Onda.D.p1,4);

  Onda.Status.diodeDriverOk = bitget(Onda.D.p2,1); % true when warmed up?
  Onda.Status.qSwitchOn = bitget(Onda.D.p2,2); % true when power is supplied
  Onda.Status.ntcOk = bitget(Onda.D.p2,3); % true when power is supplied
  Onda.Status.warmUpOk = bitget(Onda.D.p2,4); % true when warmed up
  Onda.Status.systemOk = bitget(Onda.D.p2,5);
  Onda.Status.laserOn = bitget(Onda.D.p2,6); % same as emission?
  Onda.Status.interlock = bitget(Onda.D.p2,7);
  Onda.Status.fiveVolt = bitget(Onda.D.p2,8);

  if ~Onda.Status.systemOk
    short_warn('[Onda] Laser system failure! Is the power supply connected?');
  elseif ~Onda.Status.systemOk && Onda.Status.qSwitchOn
    short_warn('[Onda] Laser has power but still needs to warm up!');
  elseif ~Onda.Status.interlock
    short_warn('[Onda] Laser off, need to press big red button!');
  end

  if printStatus
    Onda.Print_Laser_Status(1);
  end
end
