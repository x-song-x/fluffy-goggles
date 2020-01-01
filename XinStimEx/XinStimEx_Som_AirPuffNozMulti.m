%% Xintrinsic Stimulation:
% Somatosensory: Air Puff Nozzle Multiplied

% close all;
clearvars;
global stm sys

%% Synthesize the air puff seq
stm.Som.HardwareTrigger =       0;          % default

%% Oral + Face + Hand 
% stm.Som.IndStimNum =                3;      % independent stimulation number
% stm.Som.Ses.DurTotal =              414;
% 
% stm.Som.Trial(1).StimChCode =       1;      % 00000001  Oral: 18 reps
% stm.Som.Trial(1).DurTotal =         23;         
% stm.Som.Trial(1).DurStim =          2;
% stm.Som.Trial(1).PuffFreq =         10;
% stm.Som.Trial(1).PuffDutyCycle =    0.5;
% 
% stm.Som.Trial(2).StimChCode =       62;     % 00111110  Hand: 20 reps
% stm.Som.Trial(2).DurTotal =         20.7;
% stm.Som.Trial(2).DurStim =          3.8;
% stm.Som.Trial(2).PuffFreq =         4;
% stm.Som.Trial(2).PuffDutyCycle =    0.5;
% 
% stm.Som.Trial(3).StimChCode =       64;     % 01000000  Face: 23 reps
% stm.Som.Trial(3).DurTotal =         18;         
% stm.Som.Trial(3).DurStim =          2;
% stm.Som.Trial(3).PuffFreq =         4;
% stm.Som.Trial(3).PuffDutyCycle =    0.5;
% 
% stm.Som.HardwareTrigger =       1;

%% Oral + Face + LowerJaw 
% stm.Som.IndStimNum =                3;      % independent stimulation number
% stm.Som.Ses.DurTotal =              396;
% stm.Som.Ses.DurStim =               4;
% 
% stm.Som.Trial(1).StimChCode =       1;      % 00000001  Oral: 18 reps
% stm.Som.Trial(1).DurTotal =         22;         
% stm.Som.Trial(1).DurStim =          3;
% stm.Som.Trial(1).PuffFreq =         10;
% stm.Som.Trial(1).PuffDutyCycle =    0.1;
% 
% stm.Som.Trial(2).StimChCode =       2;	% 00001010  LowerJaw: 20 reps
% stm.Som.Trial(2).DurTotal =         19.8;
% stm.Som.Trial(2).DurStim =          3;
% stm.Som.Trial(2).PuffFreq =         10;
% stm.Som.Trial(2).PuffDutyCycle =    0.3;
% 
% stm.Som.Trial(3).StimChCode =       4+8;      % 00000100  Face: 22 reps
% stm.Som.Trial(3).DurTotal =         18;         
% stm.Som.Trial(3).DurStim =          stm.Som.Ses.DurStim;
% stm.Som.Trial(3).PuffFreq =         10;
% stm.Som.Trial(3).PuffDutyCycle =    0.3;
% 
% stm.Som.HardwareTrigger =       1;

%% Oral + Facial + Masking 
stm.Som.IndStimNum =                3;      % independent stimulation number
stm.Som.Ses.DurTotal =              437;
stm.Som.Ses.PuffDutyCycle =         0.3;
i = 1 ;
stm.Som.Trial(i).StimChCode =       1;      % 00000001  Oral: 19 reps
stm.Som.Trial(i).DurTotal =         23;         
stm.Som.Trial(i).DurStim =          4;
stm.Som.Trial(i).PuffFreq =         10;
stm.Som.Trial(i).PuffDutyCycle =    stm.Som.Ses.PuffDutyCycle;
i = 2;
stm.Som.Trial(i).StimChCode =       10;     % 00111110  Facial: 23 reps
stm.Som.Trial(i).DurTotal =         19;
stm.Som.Trial(i).DurStim =          4;
stm.Som.Trial(i).PuffFreq =         10;
stm.Som.Trial(i).PuffDutyCycle =    stm.Som.Ses.PuffDutyCycle;
i = 3;                                      % Masking Ch should be the last
stm.Som.Trial(i).StimChCode =       116;      % 01000000  Masking: 23 reps
stm.Som.Trial(i).DurTotal =         19;         
stm.Som.Trial(i).DurStim =          19;
stm.Som.Trial(i).PuffFreq =         10;
stm.Som.Trial(i).PuffDutyCycle =    stm.Som.Ses.PuffDutyCycle;
stm.Som.Trial(i).MaskingCh =        true; 

% stm.Som.HardwareTrigger =       1;

%% Routine Numbers
stm.SR =                    100e3;
stm.Som.SmplNumSesTotal =   round(stm.SR*stm.Som.Ses.DurTotal);
stm.Som.seq =               zeros(stm.Som.SmplNumSesTotal, 1);
stm.Som.seqOn =             stm.Som.seq;

figure
for i = 1:stm.Som.IndStimNum
    stm.Som.Trial(i).RepNum =   round(stm.Som.Ses.DurTotal/stm.Som.Trial(i).DurTotal);
    stm.Som.Trial(i).DurPreStim =   (stm.Som.Trial(i).DurTotal - stm.Som.Trial(i).DurStim)/2;
    stm.Som.Trial(i).DurPostStim =  (stm.Som.Trial(i).DurTotal - stm.Som.Trial(i).DurStim)/2;
    stm.Som.Trial(i).SmplNumTrialPreStim =	round(stm.SR*stm.Som.Trial(i).DurPreStim); 
    stm.Som.Trial(i).SmplNumTrialPostStim = round(stm.SR*stm.Som.Trial(i).DurPostStim);
    
    stm.Som.Trial(i).PuffNum =  round(stm.Som.Trial(i).DurStim*stm.Som.Trial(i).PuffFreq);
    stm.Som.Trial(i).SmplNumPuffOn =    round(stm.SR/stm.Som.Trial(i).PuffFreq* stm.Som.Trial(i).PuffDutyCycle);
    stm.Som.Trial(i).SmplNumPuffOff =	round(stm.SR/stm.Som.Trial(i).PuffFreq* (1-stm.Som.Trial(i).PuffDutyCycle));
    
        stm.Som.Trial(i).seq = zeros(0,1);
        stm.Som.Trial(i).seq = [stm.Som.Trial(i).seq;   zeros(stm.Som.Trial(i).SmplNumTrialPreStim,1)];
    for k = 1:stm.Som.Trial(i).PuffNum
        stm.Som.Trial(i).seq = [stm.Som.Trial(i).seq;   ones( stm.Som.Trial(i).SmplNumPuffOn,1)*stm.Som.Trial(i).StimChCode];
        stm.Som.Trial(i).seq = [stm.Som.Trial(i).seq;   zeros(stm.Som.Trial(i).SmplNumPuffOff,1)];
    end
        stm.Som.Trial(i).seq = [stm.Som.Trial(i).seq;   zeros(stm.Som.Trial(i).SmplNumTrialPostStim,1)];
        stm.Som.Trial(i).seq = repmat(stm.Som.Trial(i).seq, stm.Som.Trial(i).RepNum, 1);        
    try
        if isfield(stm.Som.Trial(i), 'MaskingCh')
            if i==stm.Som.IndStimNum
                if stm.Som.Trial(i).MaskingCh
                    stm.Som.Trial(i).seq = stm.Som.Trial(i).seq .* (stm.Som.seq==0);
                end
            end
        end
                stm.Som.seq = stm.Som.seq + stm.Som.Trial(i).seq;
    catch
        errordlg('length not right');
        return
    end    
    subplot(stm.Som.IndStimNum, 1, i)
    plot(stm.Som.Trial(i).seq);
end
drawnow;
stm.Som.seq = uint32(stm.Som.seq);

%% Setup NI-DAQ
    sys.taskName = 'Air Puff Nozzle Multiple';
    import dabs.ni.daqmx.*
    sys.NIDAQ.TaskDO = Task(sys.taskName);
    sys.NIDAQ.TaskDO.createDOChan(...
        'Dev3',     'port0/line0:7');
    sys.NIDAQ.TaskDO.cfgSampClkTiming(...
        stm.SR,     'DAQmx_Val_ContSamps',	stm.Som.SmplNumSesTotal );
%     sys.NIDAQ.TaskDO.cfgSampClkTiming(...
%         stm.SR,     'DAQmx_Val_FiniteSamps',	stm.Som.SmplNumSesTotal );
if stm.Som.HardwareTrigger 
    sys.NIDAQ.TaskDO.cfgDigEdgeStartTrig(... 
        'RTSI6',	'DAQmx_Val_Rising');
end
    sys.NIDAQ.TaskDO.writeDigitalData(      stm.Som.seq);
    sys.NIDAQ.TaskDO.start();
    
%% Play until cancelled
disp('ready to be triggered!');
close(gcf)
pause;
sys.NIDAQ.TaskDO.abort();
sys.NIDAQ.TaskDO.delete;
% Reset
    sys.NIDAQ.TaskDO = Task(sys.taskName);
    sys.NIDAQ.TaskDO.createDOChan(...
        'Dev3',     'port0/line0:7');
    sys.NIDAQ.TaskDO.cfgSampClkTiming(...
        stm.SR,     'DAQmx_Val_ContSamps',	stm.Som.SmplNumSesTotal );
    sys.NIDAQ.TaskDO.writeDigitalData(      uint32(stm.Som.seq*0));
    sys.NIDAQ.TaskDO.start();
    pause(1);
    sys.NIDAQ.TaskDO.abort();
    sys.NIDAQ.TaskDO.delete;



%% Oral + Hand 
% stm.Som.IndStimNum =                2;      % independent stimulation number
% stm.Som.Ses.DurTotal =              437;
% 
% stm.Som.Trial(1).StimChCode =       1;      % 00000001  Orofacial: 23 reps
% stm.Som.Trial(1).DurTotal =         19;         
% stm.Som.Trial(1).DurStim =          2;
% stm.Som.Trial(1).PuffFreq =         10;
% stm.Som.Trial(1).PuffDutyCycle =    0.5;
% 
% stm.Som.Trial(2).StimChCode =       62;     % 00111110  Hand: 19 reps
% stm.Som.Trial(2).DurTotal =         23;
% stm.Som.Trial(2).DurStim =          4;
% stm.Som.Trial(2).PuffFreq =         10;
% stm.Som.Trial(2).PuffDutyCycle =    0.5;
% 
% stm.Som.HardwareTrigger =       1;