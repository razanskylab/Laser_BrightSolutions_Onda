% Update status
function Print_Laser_Status(Obj,printStatus)
  Obj.VPrintF_With_ID('Laser status summary:\n')

  if printStatus % print this always as short status
    if Obj.emission
      fprintf('   Emission = On | ');
    else
      fprintf('   Emission = Off | ');
    end
    if Obj.aimBeam
      fprintf('   Aim = On | ');
    else
      fprintf('   Aim = Off | ');
    end
    if Obj.trigMode
      fprintf('   Trig = Ext\n');
    else
      fprintf('   Trig = Int\n');
    end
  end

  if printStatus == 2
    fprintf('   diodeDriverOk %i\n',Obj.Status.diodeDriverOk);
    fprintf('   qSwitchOn %i\n',Obj.Status.qSwitchOn);
    fprintf('   ntcOk %i\n',Obj.Status.ntcOk);
    fprintf('   warmUpOk %i\n',Obj.Status.warmUpOk);
    fprintf('   systemOk %i\n',Obj.Status.systemOk);
    fprintf('   laserOn %i\n',Obj.Status.laserOn);
    fprintf('   interlock %i\n',Obj.Status.interlock);
    fprintf('   fiveVolt %i\n',Obj.Status.fiveVolt);
  end
end
