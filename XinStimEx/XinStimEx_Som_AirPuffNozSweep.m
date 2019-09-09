%% Xintrinsic Stimulation:
% Somatosensory: Air Puff Nozzle Sweep

% close all;
clearvars;
global stm sys

%% Synthesize the air puff seq
stm.SR =                    100e3;
stm.TrialTime =             20;

%% 2 nozzles: P0.5: stimulating, P0.2: masking
stm.TrialPreStimTime =      0;
stm.TrialStimTime =         20;
stm.TrialStimChanNum =      8;
stm.TrialPuffSeqTime =      2.5;
stm.TrialStimChanBitSeq =   [2 2 2 5 2 2 2 2];

%% 7 nozzles
% % stm.TrialPreStimTime =      2.5;
% % stm.TrialStimTime =         15.0;
% stm.TrialPreStimTime =      2.3;
% stm.TrialStimTime =         15.4;
% stm.TrialStimChanNum =      7;
% stm.TrialPuffSeqTime =      2.2;
% % stm.TrialStimChanBitSeq =   [0 1 2 3 4 5 6];
% stm.TrialStimChanBitSeq =   [5 4 6 0 2 1 3];

%% 5 nozzles
% stm.TrialPreStimTime =      2.5;
% stm.TrialStimTime =         15;
% stm.TrialStimChanNum =      5;
% stm.TrialStimChanBitSeq =   [5 4 6 0 2];

%% 4 nozzles
% stm.TrialPreStimTime =      3;
% stm.TrialStimTime =         14;
% stm.TrialStimChanNum =      2;
% stm.TrialStimChanNormSeq =   [2^5 2^0+2^3+2^4];
% 
stm.TrialPuffFreq =         10;
stm.TrialPuffDutyCycle =	0.5;

stm.SmplNumTrialPreStim =	round(stm.SR*stm.TrialPreStimTime); 
stm.PuffNum =               	  stm.TrialPuffSeqTime*stm.TrialPuffFreq;
stm.SmplNumPuffOn =         round(stm.SR/stm.TrialPuffFreq*   stm.TrialPuffDutyCycle);
stm.SmplNumPuffOff =        round(stm.SR/stm.TrialPuffFreq*(1-stm.TrialPuffDutyCycle));
stm.SmplNumPostPuff =       round(stm.SR*(stm.TrialStimTime/stm.TrialStimChanNum - stm.TrialPuffSeqTime));
stm.SmplNumTrialPostStim =	round(stm.SR* (stm.TrialTime-stm.TrialPreStimTime-stm.TrialStimTime) );

        stm.seq =           zeros(stm.SmplNumTrialPreStim,1);
for i = 1:stm.TrialStimChanNum
    stm.CurrentBit =        stm.TrialStimChanBitSeq(i);
    stm.CurrentBitNorm =    2^stm.CurrentBit;
%     stm.CurrentBitNorm =    stm.TrialStimChanNormSeq(i);
    for j = 1:stm.PuffNum
        stm.seq = [stm.seq; ones( stm.SmplNumPuffOn,1)*stm.CurrentBitNorm];
        stm.seq = [stm.seq; zeros(stm.SmplNumPuffOff,1)];
    end
        stm.seq = [stm.seq; zeros(stm.SmplNumPostPuff,1)];
end
        stm.seq = [stm.seq; zeros(stm.SmplNumTrialPostStim,1)];

%% Finalize the DO Sequence
if length(stm.seq)~= stm.SR*stm.TrialTime
    errordlg('length not right');
    return
end
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

pause;
sys.NIDAQ.TaskDO.abort();
sys.NIDAQ.TaskDO.delete;