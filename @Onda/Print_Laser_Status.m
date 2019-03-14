% Update status
function Print_Laser_Status(Onda,printStatus)
  fprintf(Onda.outTarget,'[Onda] Laser status summary:\n')

  if printStatus % print this always as short status
    if Onda.emission
      fprintf(Onda.outTarget,'Emission = On | ');
    else
      fprintf(Onda.outTarget,'Emission = Off | ');
    end
    if Onda.aimBeam
      fprintf(Onda.outTarget,'Aim = On | ');
    else
      fprintf(Onda.outTarget,'Aim = Off | ');
    end
    if Onda.trigMode
      fprintf(Onda.outTarget,'Trig = Ext\n');
    else
      fprintf(Onda.outTarget,'Trig = Int\n');
    end
  end

  if printStatus == 2
    fprintf(Onda.outTarget,'diodeDriverOk %i\n',Onda.Status.diodeDriverOk)
    fprintf(Onda.outTarget,'qSwitchOn %i\n',Onda.Status.qSwitchOn);
    fprintf(Onda.outTarget,'ntcOk %i\n',Onda.Status.ntcOk);
    fprintf(Onda.outTarget,'warmUpOk %i\n',Onda.Status.warmUpOk);
    fprintf(Onda.outTarget,'systemOk %i\n',Onda.Status.systemOk);
    fprintf(Onda.outTarget,'laserOn %i\n',Onda.Status.laserOn);
    fprintf(Onda.outTarget,'interlock %i\n',Onda.Status.interlock);
    fprintf(Onda.outTarget,'fiveVolt %i\n',Onda.Status.fiveVolt);
  end
end
