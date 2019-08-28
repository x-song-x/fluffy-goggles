function XinStimEx_Vis_MT_Localizer_Callback(~,~)
global stm sys
%% Start a Cycle
% This function is called everytime 
%   stm.TimerOption = 'simulated':  an event happens on the software timer
%   stm.TimerOption = 'NI-DAQ':     a signal event happens on the hardware CO
if toc(stm.SesCycleTimeInitial) > 0.1    
    % This "if" is necessary for 'NI-DAQ' to require
    % at least 0.1s between real rising-edge triggering events to avoid 
    % pseudo-triggering by the falling-edge events
    sys.SesCycleNumCurrent =   sys.SesCycleNumCurrent + 1;
    stm.SesCycleTimeInitial =  tic;
    tt = datestr(now, 'HH:MM:SS.FFF');
    disp([sprintf('cycle: #%d ', sys.SesCycleNumCurrent), tt]);
    drawnow;
    if ~ishandle(sys.MsgBox)
        sys.SesCycleNumCurrent = sys.SesCycleNumTotal +1;
    end
end
%% Stop the session
if sys.SesCycleNumCurrent == sys.SesCycleNumTotal + 1  
    stm.Running =               0;    
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
    
