function XinStimEx_VisSom_Localizer_Callback(~,~)
global stm sys
%% Start a Cycle
% This function is called everytime 
%   stm.Vis.TimerOption = 'simulated':  an event happens on the software timer
%   stm.Vis.TimerOption = 'NI-DAQ':     a signal event happens on the hardware CO
if toc(stm.Vis.CycleDurCurrentTimer) > 0.1    
    % This "if" is necessary for 'NI-DAQ' to require
    % at least 0.1s between real rising-edge triggering events to avoid 
    % pseudo-triggering by the falling-edge events
    stm.Vis.CycleNumCurrent =   stm.Vis.CycleNumCurrent + 1;
    stm.Vis.CycleDurCurrentTimer =  tic;
    tt = datestr(now, 'HH:MM:SS.FFF');
    disp([sprintf('cycle: #%d ', stm.Vis.CycleNumCurrent), tt]); 
    if strcmp(stm.Vis.SesOption, 'Cali')
        cali_run(stm.Vis.CycleNumCurrent);
    end
    drawnow;
    if isfield(sys, 'MsgBox')
        if ~ishandle(sys.MsgBox)
            stm.Vis.CycleNumCurrent = stm.Vis.CycleNumTotal +1;
        end
    end
end
%% Stop the session
if stm.Vis.CycleNumCurrent == stm.Vis.CycleNumTotal + 1  
    stm.Vis.Running =               0;    
    try
        sys.NIDAQ.TaskCO.abort();
        sys.NIDAQ.TaskCO.delete;
    catch
        disp('hardware not found, stopping the software timer');
        sys.TimerH.stop;
        sys.TimerH.delete;
        try sys.MsgBox.delete();    catch
        end
    end    
end
    
