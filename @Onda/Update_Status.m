% Update status
function Update_Status(Obj,printStatus)
  if nargin < 2
    printStatus = 1;
  end
  Obj.VPrintF_With_ID('Updating laser status.\n');
  Obj.Query_Command('90000000');
  % laser emission status etc
  Obj.trigMode = bitget(Obj.D.p1,1);
  Obj.aimBeam = bitget(Obj.D.p1,3);
  Obj.emission = bitget(Obj.D.p1,4);

  Obj.Status.diodeDriverOk = bitget(Obj.D.p2,1); % true when warmed up?
  Obj.Status.qSwitchOn = bitget(Obj.D.p2,2); % true when power is supplied
  Obj.Status.ntcOk = bitget(Obj.D.p2,3); % true when power is supplied
  Obj.Status.warmUpOk = bitget(Obj.D.p2,4); % true when warmed up
  Obj.Status.systemOk = bitget(Obj.D.p2,5);
  Obj.Status.laserOn = bitget(Obj.D.p2,6); % same as emission?
  Obj.Status.interlock = bitget(Obj.D.p2,7);
  Obj.Status.fiveVolt = bitget(Obj.D.p2,8);

  if ~Obj.Status.systemOk
    short_warn('[Onda] Laser system failure! Is the power supply connected?');
  elseif ~Obj.Status.systemOk && Obj.Status.qSwitchOn
    short_warn('[Onda] Laser has power but still needs to warm up!');
  elseif ~Obj.Status.interlock
    short_warn('[Onda] Laser off, need to press big red button!');
  end

  if printStatus
    Obj.Print_Laser_Status(1);
  end
end
