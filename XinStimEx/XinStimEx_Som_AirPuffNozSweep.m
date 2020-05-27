%% Xintrinsic Stimulation:
% Somatosensory: Air Puff Nozzle Sweep

% close all;
clearvars;
global stm sys
stm.SR =                    100e3;

%% Synthesize the air puff seq

%% 2 nozzles: P0.5: stimulating, P0.2: masking
stm.Som.HardwareTrigger =       0;          % default
stm.Som.TrialTime =             20;
stm.Som.TrialPreStimTime =      0;
stm.Som.TrialStimTime =         20;
% stm.Som.TrialStimChanNum =      8;
% stm.Som.TrialPuffSeqTime =      2.5;
% 
% % stm.Som.TrialStimChanBitSeq =   [2 2 2 6 2 2 2 2];
% % stm.Som.TrialStimChanBitSeq =   [5 5 5 6 6 5 5 5];
% % stm.Som.TrialStimChanBitSeq =   0*stm.Som.TrialStimChanBitSeq;
% % stm.Som.TrialStimChanBitSeq =   [4 4 0 0 0 0 4 4];
% stm.Som.TrialStimChanBitSeq =   [4 4 5 5 5 5 4 4];
% stm.Som.TrialStimChanNormSeq =   [64 64 36 36 36 36 64 64];


% stm.Som.TrialStimChanNum =      8;
% stm.Som.TrialPuffSeqTime =      2.5;
% stm.Som.TrialStimChanBitSeq =   [2 2 2 6 2 2 2 2];
% stm.Som.TrialStimChanBitSeq =   [5 5 5 6 6 5 5 5];
% stm.Som.TrialStimChanBitSeq =   0*stm.Som.TrialStimChanBitSeq;
% stm.Som.TrialStimChanBitSeq =   [4 4 0 0 0 0 4 4];
% stm.Som.TrialStimChanBitSeq =   [0 0 0 0];

% stm.Som.TrialStimChanNormSeq =  [62 1 1 64 64 1 1 62];
% stm.Som.TrialStimChanNormSeq =  [64 64 64 1 1 64 64 64];    % Orofacial

% stm.Som.TrialStimChanNormSeq =  [64 0 0  1 1 0  0 64];        % 1-port orofacial vs 1-port masking


% stm.Som.TrialStimChanNum =      20;
% stm.Som.TrialPuffSeqTime =      1;
% stm.Som.TrialStimChanNormSeq =  [64 zeros(1,8), 1, 1, zeros(1,8), 64];	% Orofacial@1(mid) & masking@1(end)
% stm.Som.TrialStimChanNormSeq =  [   zeros(1,9), 1, 1, zeros(1,9)    ];	% Orofacial@1(mid) & no masking
% stm.Som.TrialStimChanNormSeq =  [   zeros(1,7), 62, 62, zeros(1,11)    ];	% Hand@7(mid) & no masking
% stm.Som.TrialStimChanNormSeq =  [   zeros(1,7), [62 62 0 0 1 1] zeros(1,7)    ];	% Hand@7 + Orofacial@1 & no masking
% stm.Som.TrialStimChanNormSeq =  [   120*ones(1,5), [0 0 0 0 6 6 0 0 0 0] 120*ones(1,5)];	% Hand@4 + masking@4

% % stm.Som.TrialStimChanNormSeq =  [64 64 0 1 0 0 62 0 64 64];        % Orofacial & Hand
% stm.Som.TrialStimChanNormSeq =  [zeros(1, 9), [64 64], zeros(1, 9)];        % Hand & Orofacial

% stm.Som.TrialStimChanNum =      10;
% stm.Som.TrialPuffSeqTime =      2;
% % stm.Som.TrialStimChanNormSeq =  [ 120 0 0 0 6 6 0 0 0 120];	% Hand@4c + masking@4c
% % stm.Som.TrialStimChanNormSeq =  [ 120 0 0 0 6 0 0 0 120 120];	% Hand@4c + masking@4c
% stm.Som.TrialStimChanNormSeq =  [ 120 0 6 0 0 1 0 0 120 120];	% Hand@4c + oro@1c + masking@4c

% stm.Som.TrialStimChanNum =      10;
% stm.Som.TrialPuffSeqTime =      2;
% stm.Som.TrialStimChanNormSeq =  [ 120 0 0 0 6 6 0 0 0 120];	% Hand@4c + masking@4c
% stm.Som.TrialStimChanNormSeq =  [ 120 0 0 0 6 0 0 0 120 120];	% Hand@4c + masking@4c
% stm.Som.TrialStimChanNormSeq =  (1)*ones(1, 10);	%
% stm.Som.TrialStimChanNormSeq =  (116)*ones(1, 10);	%
% stm.Som.HardwareTrigger =       1;


%% 7 nozzles
% % stm.Som.TrialPreStimTime =      2.5;
% % stm.Som.TrialStimTime =         15.0;
% stm.Som.TrialPreStimTime =      2.3;
% stm.Som.TrialStimTime =         15.4;
% stm.Som.TrialStimChanNum =      7;
% stm.Som.TrialPuffSeqTime =      2.2;
% % stm.Som.TrialStimChanBitSeq =   [0 1 2 3 4 5 6];
% stm.Som.TrialStimChanBitSeq =   [5 4 6 0 2 1 3];

%% 5 nozzles
% stm.Som.TrialPreStimTime =      2.5;
% stm.Som.TrialStimTime =         15;
% stm.Som.TrialStimChanNum =      5;
% stm.Som.TrialStimChanBitSeq =   [5 4 6 0 2];

%% 4 nozzles
% stm.Som.TrialPreStimTime =      3;
% stm.Som.TrialStimTime =         14;
% stm.Som.TrialStimChanNum =      2;
% stm.Som.TrialStimChanNormSeq =   [2^5 2^0+2^3+2^4];


stm.Som.TrialStimChanNum =      10;
stm.Som.TrialPuffSeqTime =      2;
stm.Som.TrialStimChanNormSeq =  (116)*ones(1, 10);	%

stm.Som.TrialPuffFreq =         10;
stm.Som.TrialPuffDutyCycle =	0.5;


stm.Som.SmplNumTrialPreStim =	round(stm.SR*stm.Som.TrialPreStimTime); 
stm.Som.PuffNum =               	  stm.Som.TrialPuffSeqTime*stm.Som.TrialPuffFreq;
stm.Som.SmplNumPuffOn =         round(stm.SR/stm.Som.TrialPuffFreq*   stm.Som.TrialPuffDutyCycle);
stm.Som.SmplNumPuffOff =        round(stm.SR/stm.Som.TrialPuffFreq*(1-stm.Som.TrialPuffDutyCycle));
stm.Som.SmplNumPostPuff =       round(stm.SR*(stm.Som.TrialStimTime/stm.Som.TrialStimChanNum - stm.Som.TrialPuffSeqTime));
stm.Som.SmplNumTrialPostStim =	round(stm.SR* (stm.Som.TrialTime-stm.Som.TrialPreStimTime-stm.Som.TrialStimTime) );

        stm.Som.seq =           zeros(stm.Som.SmplNumTrialPreStim,1);
for i = 1:stm.Som.TrialStimChanNum
    
%     stm.Som.CurrentBit =        stm.Som.TrialStimChanBitSeq(i);
%     stm.Som.CurrentBitNorm =    2^stm.Som.CurrentBit;
    stm.Som.CurrentBitNorm =    stm.Som.TrialStimChanNormSeq(i);
    for j = 1:stm.Som.PuffNum
        stm.Som.seq = [stm.Som.seq; ones( stm.Som.SmplNumPuffOn,1)*stm.Som.CurrentBitNorm];
        stm.Som.seq = [stm.Som.seq; zeros(stm.Som.SmplNumPuffOff,1)];
    end
        stm.Som.seq = [stm.Som.seq; zeros(stm.Som.SmplNumPostPuff,1)];
end
        stm.Som.seq = [stm.Som.seq; zeros(stm.Som.SmplNumTrialPostStim,1)];

%% Finalize the DO Sequence
if length(stm.Som.seq)~= stm.SR*stm.Som.TrialTime
    errordlg('length not right');
    return
end
plot(stm.Som.seq);
stm.Som.seq = uint32(stm.Som.seq);

%% Setup NI-DAQ
sys.taskName = 'Air Puff Nozzle Multiple';
import dabs.ni.daqmx.*
sys.NIDAQ.TaskDO = Task(sys.taskName);
sys.NIDAQ.TaskDO.createDOChan(...
    'Dev3',     'port0/line0:7');
sys.NIDAQ.TaskDO.cfgSampClkTiming(...
	stm.SR,     'DAQmx_Val_ContSamps',	stm.Som.TrialTime*stm.SR);
if stm.Som.HardwareTrigger 
sys.NIDAQ.TaskDO.cfgDigEdgeStartTrig(... 
	'RTSI6',	'DAQmx_Val_Rising');
end
sys.NIDAQ.TaskDO.writeDigitalData(      stm.Som.seq);
sys.NIDAQ.TaskDO.start();

%% Play until cancelled
disp('ready to be ended!');
pause;
sys.NIDAQ.TaskDO.abort();
sys.NIDAQ.TaskDO.writeDigitalData(uint32(0));
sys.NIDAQ.TaskDO.delete;
% Reset
    sys.NIDAQ.TaskDO = Task(sys.taskName);
    sys.NIDAQ.TaskDO.createDOChan(...
        'Dev3',     'port0/line0:7');
    sys.NIDAQ.TaskDO.cfgSampClkTiming(...
        stm.SR,     'DAQmx_Val_ContSamps',	stm.Som.TrialTime*stm.SR);
    sys.NIDAQ.TaskDO.writeDigitalData(      uint32(stm.Som.seq*0));
    sys.NIDAQ.TaskDO.start();
    pause(1);
    sys.NIDAQ.TaskDO.abort();
    sys.NIDAQ.TaskDO.delete;
