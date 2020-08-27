%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Set_Trigger_Source(Obj, triggerMode)
  if triggerMode > 1
    short_warn('[Onda] Unknown trigger mode. Not sure what to do...')
  elseif triggerMode == 0
    Obj.VPrintF_With_ID('Setting trigger source: Internal.\n');
    Obj.Query_Command('82000000');
    Obj.trigMode = 0;
  elseif triggerMode == 1
    Obj.VPrintF_With_ID('Setting trigger source: External.\n');
    Obj.Query_Command('82010000');
    Obj.trigMode = 1;
  end
end
