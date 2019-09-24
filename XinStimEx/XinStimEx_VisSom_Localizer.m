%% MT localizer with multiple options

%% Switch multi-display mode
dos('C:\Windows\System32\DisplaySwitch.exe /extend');
sca;                    % Clear the screen       
pause(2);

clearvars;              % Clear the workspace
global stm sys

stm.SR = 100e3;

stm.Som.TrialTime =             20;
stm.Som.TrialPreStimTime =      0;
stm.Som.TrialStimTime =         20;
stm.Som.TrialStimChanNum =      8;
stm.Som.TrialPuffSeqTime =      2.5;
stm.Som.TrialStimChanBitSeq =   [2 2 2 6 2 2 2 2];

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
    stm.Som.CurrentBit =        stm.Som.TrialStimChanBitSeq(i);
    stm.Som.CurrentBitNorm =    2^stm.Som.CurrentBit;
%     stm.Som.CurrentBitNorm =    stm.Som.TrialStimChanNormSeq(i);
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
% plot(stm.Som.seq);
stm.Som.seq = uint32(stm.Som.seq);

%% Specify Session Parameters

% Session Timer 
% stm.Vis.TimerOption =       'simulated';
stm.Vis.TimerOption =       'NI-DAQ';

% Session Type Options
stm.Vis.SesOption =         'DLCL';  % Dot Localizer

stm.Vis.SesCycleTime =              20;     % in second
sys.SesCycleNumTotal =          20;     % rep # total
sys.SesCycleNumCurrent =        0;
stm.Vis.SesCycleTimeInitial =       tic;

% Display Device
% stm.Vis.MonitorName =       'Dell P2416D';
% stm.Vis.MonitorDistance =   75;         % in cm
% stm.Vis.MonitorHeight =     29.5;       % in cm
% stm.Vis.MonitorWidth =      52.7;       % in cm
stm.Vis.MonitorName =       'Samsung LG 32GK850F-B';
stm.Vis.MonitorDistance =   75;             % in cm
stm.Vis.MonitorHeight =     0.02724*1440;	% in cm
stm.Vis.MonitorWidth =      0.02724*2560;	% in cm

%% Prepare the Psychtoolbox window
% Here we call some default settings for setting up Psychtoolbox
                                                PsychDefaultSetup(2);
% Draw to the external screen
screenNumber = 1;
% Define black and white
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);               
                                                Screen('Preference', 'VisualDebugLevel', 1);
                                                Screen('Preference', 'SkipSyncTests', 1);
% Open an on screen window
[stm.Vis.windowPtr, windowRect] =                   PsychImaging('OpenWindow', screenNumber, black);
% Query: Get the size of the on screen window
[stm.Vis.MonitorPixelNumX, stm.Vis.MonitorPixelNumY] =  Screen('WindowSize', stm.Vis.windowPtr);
% Query: the frame duration
stm.Vis.TrialIFI =                                  Screen('GetFlipInterval', stm.Vis.windowPtr);
% Querry the max dot size allowed
[~, stm.Vis.DotDiameterInPixelMax, ~, ~] =          Screen('DrawDots', stm.Vis.windowPtr);

%% Initialize parameters
switch stm.Vis.SesOption(1)
    case 'C'
%         cali_init(stm.Vis.windowPtr, @generate_half_sequence, 'dot', 0.5);  % 80 x 5s
%         cali_init(stm.Vis.windowPtr, @partition_small, 'face', 1);  % 20 x 20s
%         cali_init(stm.Vis.windowPtr, @partition_large, 'face', 1);  % 20 x 20s   
%         cali_init(stm.Vis.windowPtr, @generate_half_sequence, 'face', 1);  % 80 x 1, 2, 4s 
%         cali_init(stm.Vis.windowPtr, @partition_small, 'face', 0.5);  % 20 x 20s
%         cali_init(stm.Vis.windowPtr, @generate_half_sequence, 'dot', 0.5);   % 80 x 5s
    case 'D'
        stm.Vis.DotDiameter =       0.4;        % in degree
        stm.Vis.DotMotionSpeedMax =	16;         % in degree / second
        stm.Vis.DotDensityAngle =   180;        % as how many dots are in the field

        stm.Vis.MonitorAngleX =         2*atan(stm.Vis.MonitorWidth/2/stm.Vis.MonitorDistance)/pi*180;  
        stm.Vis.MonitorAngleY =         2*atan(stm.Vis.MonitorHeight/2/stm.Vis.MonitorDistance)/pi*180;
        stm.Vis.MonitorPixelAngleX =    stm.Vis.MonitorAngleX/stm.Vis.MonitorPixelNumX;
        stm.Vis.MonitorPixelAngleY =    stm.Vis.MonitorAngleY/stm.Vis.MonitorPixelNumY;
        stm.Vis.MonitorPixelAngle =     mean([stm.Vis.MonitorPixelAngleX stm.Vis.MonitorPixelAngleY]);
        stm.Vis.MonitorCenter =         [stm.Vis.MonitorPixelNumX/2 stm.Vis.MonitorPixelNumY/2];
        stm.Vis.DotDiameterInPixel =    stm.Vis.DotDiameter/stm.Vis.MonitorPixelAngle;
        if stm.Vis.DotDiameterInPixel > stm.Vis.DotDiameterInPixelMax
            errordlg('Dot diameter set too big!')
        end
        stm.Vis.DotCenterRadiusMax =    stm.Vis.MonitorAngleY/2;
        stm.Vis.DotVecLength =          stm.Vis.DotDensityAngle*1;
        stm.Vis.DotVecAngle =           rand(1, stm.Vis.DotDensityAngle)*360;
        stm.Vis.DotVecRadius =          rand(1, stm.Vis.DotDensityAngle)*stm.Vis.DotCenterRadiusMax;
        stm.Vis.DotVecAngleInit =       stm.Vis.DotVecAngle;
        stm.Vis.DotVecRadiusInit =      stm.Vis.DotVecRadius;      
        stm.Vis.DotVecPositionX =       cos(stm.Vis.DotVecAngle/180*pi).*...
                                    (stm.Vis.DotVecRadius/stm.Vis.MonitorPixelAngleX);
        stm.Vis.DotVecPositionY =       sin(stm.Vis.DotVecAngle/180*pi).*...
                                    (stm.Vis.DotVecRadius/stm.Vis.MonitorPixelAngleY);
        stm.Vis.DotMotionStepMax =      stm.Vis.DotMotionSpeedMax*stm.Vis.TrialIFI;
        stm.Vis.TrialFrameSeq =         1:round(stm.Vis.SesCycleTime/stm.Vis.TrialIFI);
        switch stm.Vis.SesOption(2:4)
            case 'LCL'
                stm.Vis.DotMotionPeakTime =     4;    
                slope =                     1/(stm.Vis.SesCycleTime/2 - stm.Vis.DotMotionPeakTime);
                shift1 =                    slope*stm.Vis.SesCycleTime/2;
                shift2 =                    slope*(stm.Vis.SesCycleTime/2 - stm.Vis.DotMotionPeakTime/2);
            case 'RCW'
                stm.Vis.DotAngleMinInitial =    -135;
                if length(stm.Vis.SesOption)>4
                    if stm.Vis.SesOption(5) == 'F'
                        for i = 1:9
                            stm.Vis.FaceLib{i} =    imread(['D:\GitHub\EyeTrackerCalibration\images\m' num2str(i) '.png']);
                            stm.Vis.FaceTexLib(i) = Screen('MakeTexture', stm.Vis.windowPtr, stm.Vis.FaceLib{i});
                            stm.Vis.FaceTic =       tic;
                            stm.Vis.FaceTocTime =   2;
                            stm.Vis.FaceIdxCurrent = randi([1 length(stm.Vis.FaceTexLib)]);
                        end
                    end
                end
            case 'RCC'
                stm.Vis.DotAngleMinInitial =    -135;
            case 'CPS'
                stm.Vis.DotAngleDivide =        10;
        end
        Screen('DrawDots', stm.Vis.windowPtr, [stm.Vis.DotVecPositionX; stm.Vis.DotVecPositionY],...
            stm.Vis.DotDiameterInPixel, white,	stm.Vis.MonitorCenter, 2);
        vbl = Screen('Flip', stm.Vis.windowPtr);
    otherwise
end

%% Setup Timer: NI-DAQ or PC timing
switch stm.Vis.TimerOption
    case 'NI-DAQ'
        sys.NIDAQ.D.InTimebaseRate =    100e3;
        sys.NIDAQ.D.CycleSmplHigh =     2;
        sys.NIDAQ.D.CycleSmplLow =      sys.NIDAQ.D.InTimebaseRate * stm.Vis.SesCycleTime - ...
                                        sys.NIDAQ.D.CycleSmplHigh;
        import dabs.ni.daqmx.*
        sys.NIDAQ.TaskCO = Task('Recording Session Cycle Switcher');
        sys.NIDAQ.TaskCO.createCOPulseChanTicks(...
            'Dev3', 1, 'Cycle Counter', '100kHzTimebase', ...
            sys.NIDAQ.D.CycleSmplLow, sys.NIDAQ.D.CycleSmplHigh,...
            0, 'DAQmx_Val_Low');
        sys.NIDAQ.TaskCO.cfgImplicitTiming(...
            'DAQmx_Val_FiniteSamps',	sys.SesCycleNumTotal+1);
        sys.NIDAQ.TaskCO.cfgDigEdgeStartTrig(...
            'RTSI6',            'DAQmx_Val_Rising');
        sys.NIDAQ.TaskCO.registerSignalEvent(...
            @XinStimEx_VisSom_Localizer_Callback, 'DAQmx_Val_CounterOutputEvent');
        sys.NIDAQ.TaskCO.start()
        
        sys.NIDAQ.TaskDO = Task('Cochlear Implant Trigger Sequence');
        sys.NIDAQ.TaskDO.createDOChan(...
            'Dev3',     'port0/line0:7');
        sys.NIDAQ.TaskDO.cfgSampClkTiming(...
            stm.SR,     'DAQmx_Val_ContSamps',	stm.Som.TrialTime*stm.SR);
        sys.NIDAQ.TaskDO.cfgDigEdgeStartTrig(... 
            'RTSI6',	'DAQmx_Val_Rising');
        sys.NIDAQ.TaskDO.writeDigitalData(      stm.Som.seq);
        sys.NIDAQ.TaskDO.start()
        
        stm.Vis.Running =               1;
    case 'simulated'
        sys.TimerH =                timer;
        sys.TimerH.TimerFcn =       @XinStimEx_Vis_MT_Localizer_Callback;
        sys.TimerH.Period =         stm.Vis.SesCycleTime;
        sys.TimerH.TasksToExecute = sys.SesCycleNumTotal+1;
        sys.TimerH.ExecutionMode =  'fixedRate';
        sys.MsgBox =                msgbox('Click to terminate the session after current cycle');
        stm.Vis.Running =               1;
        pause;
        sys.TimerH.start;   
    otherwise
end
%% Play 
while stm.Vis.Running
    
    % Session timing
    stm.Vis.SesOn =           (   sys.SesCycleNumCurrent>0 && ...
                                    sys.SesCycleNumCurrent<=sys.SesCycleNumTotal);
    stm.Vis.SesCycleTimeCurrent =    toc(stm.Vis.SesCycleTimeInitial); 
    
    % Estimate current dot step parameters   
    if stm.Vis.SesOption(1)=='D'
        switch stm.Vis.SesOption(2:4)
            case 'LCL'
                stm.Vis.DotMotionSpeedNorm =	stm.Vis.SesOn*(...
                        min(1, max(0, shift2-abs(stm.Vis.SesCycleTimeCurrent*slope-shift1) ) )...
                                                            );
                stm.Vis.DotRadiusMinCurrent =   0;
                stm.Vis.DotRadiusMaxCurrent =   stm.Vis.MonitorAngleY/2;
                stm.Vis.DotAngleMinCurrent =    0;
                stm.Vis.DotAngleMaxCurrent =    360;
                stm.Vis.DotVecMovingIdx =       1+0*stm.Vis.DotVecRadius;
            case 'RCW'
                stm.Vis.DotMotionSpeedNorm =    1;
                stm.Vis.DotRadiusMinCurrent =   0;
                stm.Vis.DotRadiusMaxCurrent =   stm.Vis.MonitorAngleY/2;
                stm.Vis.DotAngleMinCurrent =    stm.Vis.DotAngleMinInitial+stm.Vis.SesOn*360/stm.Vis.SesCycleTime* stm.Vis.SesCycleTimeCurrent;
                stm.Vis.DotAngleMaxCurrent =    stm.Vis.DotAngleMinCurrent+90;
                stm.Vis.DotVecMovingIdx =       mod(stm.Vis.DotVecAngle-stm.Vis.DotAngleMinCurrent, 360)<90;
            case 'RCC'
                stm.Vis.DotMotionSpeedNorm =    1;
                stm.Vis.DotRadiusMinCurrent =   0;
                stm.Vis.DotRadiusMaxCurrent =   stm.Vis.MonitorAngleY/2;
                stm.Vis.DotAngleMinCurrent =    stm.Vis.DotAngleMinInitial-stm.Vis.SesOn*360/stm.Vis.SesCycleTime* stm.Vis.SesCycleTimeCurrent;
                stm.Vis.DotAngleMaxCurrent =    stm.Vis.DotAngleMinCurrent+90;
                stm.Vis.DotVecMovingIdx =       mod(stm.Vis.DotVecAngle-stm.Vis.DotAngleMinCurrent, 360)<90;
            case 'CPS'
                stm.Vis.DotMotionSpeedNorm =    1;
    %             stm.Vis.DotRadiusMinCurrent =   (cos(2*pi*stm.Vis.SesCycleTimeCurrent/stm.Vis.SesCycleTime)+1)/2 * stm.Vis.DotAngleDivide/2;
    %             stm.Vis.DotRadiusMaxCurrent =   (cos(2*pi*stm.Vis.SesCycleTimeCurrent/stm.Vis.SesCycleTime)+1)/2 * stm.Vis.MonitorAngleY/2 + ... 
    %                                         stm.Vis.DotAngleDivide/2;
                stm.Vis.DotRadiusMinCurrent =   0;
                stm.Vis.DotRadiusMaxCurrent =   stm.Vis.MonitorAngleY/2;
                stm.Vis.DotAngleMinCurrent =    0;
                stm.Vis.DotAngleMaxCurrent =    360;
                stm.Vis.DotVecMovingIdx =       stm.Vis.SesOn + 0*stm.Vis.DotVecRadius;
            otherwise
        end
        % Move the dots radially: move the ones on the DocVecMovingIdx, with DotMotionStepCurrent
        stm.Vis.DotVecIndexOut =        stm.Vis.DotVecRadius < stm.Vis.DotRadiusMaxCurrent;
        stm.Vis.DotMotionStepCurrent =  stm.Vis.DotMotionSpeedNorm*stm.Vis.DotMotionStepMax*stm.Vis.DotVecMovingIdx;
        stm.Vis.DotVecRadius =          stm.Vis.DotVecRadius + stm.Vis.DotMotionStepCurrent;
 
        % Replace the missing dots
        stm.Vis.DotVecIndexOut =        stm.Vis.DotVecIndexOut & (stm.Vis.DotVecRadius > stm.Vis.DotRadiusMaxCurrent);  
        stm.Vis.DotVecIndexIn =         ~stm.Vis.DotVecIndexOut;                      
        stm.Vis.DotVecRadius(stm.Vis.DotVecIndexOut) = ...
                                    stm.Vis.DotRadiusMinCurrent; 
        stm.Vis.DotVecAngle =           stm.Vis.DotVecIndexIn.*stm.Vis.DotVecAngle + ...
                                    stm.Vis.DotVecIndexOut.*...
                                    (  ( stm.Vis.DotAngleMinCurrent + ...
                                    (stm.Vis.DotAngleMaxCurrent-stm.Vis.DotAngleMinCurrent)*...
                                    rand(1,stm.Vis.DotVecLength) ).*stm.Vis.DotVecIndexOut  );    
        % Masking
        if strcmp(stm.Vis.SesOption(2:4), 'CPS')
            stm.Vis.DotRadiusMaskerMinCurrent =   (cos(2*pi*stm.Vis.SesCycleTimeCurrent/stm.Vis.SesCycleTime)+1)/2 * stm.Vis.DotAngleDivide/2;
            stm.Vis.DotRadiusMaskerMaxCurrent =   (cos(2*pi*stm.Vis.SesCycleTimeCurrent/stm.Vis.SesCycleTime)+1)/2 * stm.Vis.MonitorAngleY/2 + ... 
                                                    stm.Vis.DotAngleDivide/2;
            stm.Vis.DotMaskerIdx =      (stm.Vis.DotVecRadiusInit   >stm.Vis.DotRadiusMaskerMaxCurrent) | ...
                                    (stm.Vis.DotVecRadiusInit   <stm.Vis.DotRadiusMaskerMinCurrent);
            stm.Vis.DotMotionIdx =      (stm.Vis.DotVecRadius       <stm.Vis.DotRadiusMaskerMaxCurrent) & ...
                                    (stm.Vis.DotVecRadius       >stm.Vis.DotRadiusMaskerMinCurrent);   
            stm.Vis.DotVecAngleOut =	[stm.Vis.DotVecAngle(stm.Vis.DotMotionIdx)  stm.Vis.DotVecAngleInit(stm.Vis.DotMaskerIdx)];
            stm.Vis.DotVecRadiusOut =	[stm.Vis.DotVecRadius(stm.Vis.DotMotionIdx) stm.Vis.DotVecRadiusInit(stm.Vis.DotMaskerIdx)];            
        else
            stm.Vis.DotVecAngleOut =	stm.Vis.DotVecAngle;
            stm.Vis.DotVecRadiusOut =	stm.Vis.DotVecRadius;
        end

        % Translate the display coordinates
        stm.Vis.DotVecPositionX =       cos(stm.Vis.DotVecAngleOut/180*pi).*...
                                    (stm.Vis.DotVecRadiusOut/stm.Vis.MonitorPixelAngle);
        stm.Vis.DotVecPositionY =       sin(stm.Vis.DotVecAngleOut/180*pi).*...
                                    (stm.Vis.DotVecRadiusOut/stm.Vis.MonitorPixelAngle);

        %% Display 
        Screen('DrawDots', stm.Vis.windowPtr, [stm.Vis.DotVecPositionX; stm.Vis.DotVecPositionY],...
            stm.Vis.DotDiameterInPixel, white,	stm.Vis.MonitorCenter, 2);      % dots
        if length(stm.Vis.SesOption)>4
            if stm.Vis.SesOption(5) == 'F'
                if toc(stm.Vis.FaceTic)>stm.Vis.FaceTocTime
                    stm.Vis.FaceIdxCurrent = randi([1 length(stm.Vis.FaceTexLib)]);
                    stm.Vis.FaceTic = tic;
                end
                Screen('DrawTextures', stm.Vis.windowPtr, stm.Vis.FaceTexLib(stm.Vis.FaceIdxCurrent),...
                    [], (stm.Vis.MonitorCenter([1 2 1 2]) + [80 -80 -80 80])');
            end
        end                                                             % face (center attractor)
        Screen('DrawingFinished', stm.Vis.windowPtr);                       % hold
        vbl = Screen('Flip', stm.Vis.windowPtr, vbl + 0.5*stm.Vis.TrialIFI);    % flip
    else
        pause(0.1);
    end
end

%% Clear the display
% if sys.SesCycleNumCurrent < sys.SesCycleNumTotal + 1 
%     % interrupted, but not naturally finished
%     sys.SesCycleNumCurrent = sys.SesCycleNumTotal;
%     XinStimEx_Vis_MT_Localizer_Callback;
% end
pause(2);
pause;
sys.NIDAQ.TaskDO.abort();
sys.NIDAQ.TaskDO.delete;
sca;
% dos('C:\Windows\System32\DisplaySwitch.exe /clone');