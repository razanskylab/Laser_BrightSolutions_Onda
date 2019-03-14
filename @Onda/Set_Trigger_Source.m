%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Set_Trigger_Source(Onda, triggerMode)
  if triggerMode > 1
    short_warn('[Onda] Unknown trigger mode. Not sure what to do...')
  elseif triggerMode == 0
    fprintf(Onda.outTarget,'[Onda] Setting trigger source: Internal.\n');
    Onda.Query_Command('82000000');
    Onda.trigMode = 0;
  elseif triggerMode == 1
    fprintf(Onda.outTarget,'[Onda] Setting trigger source: External.\n');
    Onda.Query_Command('82010000');
    Onda.trigMode = 1;
  end
end
