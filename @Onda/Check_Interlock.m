% Open_Connection @ Onda

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = Check_Interlock(Obj)
  oldVerbose = Obj.verboseOutput;
  Obj.verboseOutput = false;
  Obj.Update_Status(false);
  needsButton = ~Obj.interlockStatus;
  while(needsButton)
    answer = questdlg('Laser disabled, need to press red button!', ...
     'Laser Interlock', 'Done','Cancel','Cancel');
    switch answer
    case 'Done'
      Obj.Update_Status(false);
      needsButton = ~Obj.interlockStatus;
    case 'Cancel'
      short_warn('Laser still interlocked!')
      return;
    end
  end 

  Obj.verboseOutput = oldVerbose;

end
