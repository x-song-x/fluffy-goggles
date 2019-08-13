function XinStim_Vis_MT_Finder_Callback(~,~)
global stm sys
if toc(sys.Ses.CycleInitialTime) > 0.1    % at least 0.1s 
    sys.Ses.CycleNumCurrent =   sys.Ses.CycleNumCurrent + 1;
    sys.Ses.CycleInitialTime =  tic;
    tt = datestr(now, 'HH:MM:SS.FFF');
    disp(tt);
end

if sys.Ses.CycleNumCurrent == sys.Ses.CycleNumTotal + 1   
    sys.NIDAQ.TaskCO.abort();
    sys.NIDAQ.TaskCO.delete;
    
    stm.Running =               0;
    
end
    

