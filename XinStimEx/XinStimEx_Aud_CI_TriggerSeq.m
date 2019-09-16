%% Xintrinsic Stimulation: External:
% Auditory: Cochlear Implant Trigger Sequence

clearvars;
global stm sys

%% Synthesize the trigger seq
stm.SR =                    100e3;
stm.TrialTime =             20;
stm.TrialPreStimTime =      2.5;
stm.TrialStimTime =         15.0;

% stm.TrialStimElectdNum =        2;
% stm.TrialPipNum =               4;
% stm.TrialPipTime =              0.25;
% stm.TrialPipDutyCycle =         0.5;

% stm.TrialStimElectdNum =        6;
% stm.TrialPipNum =               10;
% stm.TrialPipTime =              0.25;
% stm.TrialPipDutyCycle =         0.5;

stm.TrialPreStimTime =      5;
stm.TrialStimTime =         10.0;
stm.TrialStimElectdNum =        1;
stm.TrialPipNum =               40;
stm.TrialPipTime =              0.25;
stm.TrialPipDutyCycle =         0.5;
% % stm.TrialPipNum =               5;
% % stm.TrialPipTime =              0.25;
% % stm.TrialPipDutyCycle =         0.5;

% stm.TrialPreStimTime =      2;
% stm.TrialStimTime =         16;
% stm.TrialStimElectdNum =        8;
% stm.TrialPipNum =               5;
% stm.TrialPipTime =              0.25;
% stm.TrialPipDutyCycle =         0.5;

% stm.TrialPreStimTime =      4;
% stm.TrialStimTime =         16;
% stm.TrialStimElectdNum =        2;
% stm.TrialPipNum =               10;
% stm.TrialPipTime =              0.4;
% stm.TrialPipDutyCycle =         0.5;

stm.SmplNumTrialPreStim =	round(stm.SR*stm.TrialPreStimTime); 
stm.SmplNumPipOn =          round(stm.SR*stm.TrialPipTime*stm.TrialPipDutyCycle);
stm.SmplNumPipOff =         round(stm.SR*stm.TrialPipTime*(1-stm.TrialPipDutyCycle));
stm.SmplNumElectdOff =      round(stm.SR* ( stm.TrialStimTime/stm.TrialStimElectdNum -...
                                            stm.TrialPipNum*stm.TrialPipTime) );
stm.SmplNumTrialPostStim =	round(stm.SR* (stm.TrialTime-stm.TrialPreStimTime-stm.TrialStimTime) );

        stm.seq =           zeros(stm.SmplNumTrialPreStim,1);
for i = 1:stm.TrialStimElectdNum
    for j = 1:stm.TrialPipNum
        stm.seq = [stm.seq; ones( stm.SmplNumPipOn,1)];
        stm.seq = [stm.seq; zeros(stm.SmplNumPipOff,1)];
    end
        stm.seq = [stm.seq; zeros(stm.SmplNumElectdOff,1)];
end
        stm.seq = [stm.seq; zeros(stm.SmplNumTrialPostStim,1)];
        stm.seq = 255*stm.seq;
        
%% Finalize the DO Sequence
disp(length(stm.seq));
% plot(stm.seq);
stm.seq = uint32(stm.seq);

%% Setup NI-DAQ
import dabs.ni.daqmx.*
sys.NIDAQ.TaskDO = Task('Cochlear Implant Trigger Sequence');
sys.NIDAQ.TaskDO.createDOChan(...
    'Dev3',     'port0/line0:7');
sys.NIDAQ.TaskDO.cfgSampClkTiming(...
	stm.SR,     'DAQmx_Val_ContSamps',	stm.TrialTime*stm.SR);
sys.NIDAQ.TaskDO.cfgDigEdgeStartTrig(...
	'RTSI6',	'DAQmx_Val_Rising');
sys.NIDAQ.TaskDO.writeDigitalData(      stm.seq);
sys.NIDAQ.TaskDO.start();

%% Play until cancelled
disp('CO task is ready to be triggered!');
pause;
sys.NIDAQ.TaskDO.abort();
sys.NIDAQ.TaskDO.delete;