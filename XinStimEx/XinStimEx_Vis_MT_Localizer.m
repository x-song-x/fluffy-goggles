%% MT localizer with multiple options

%% Switch multi-display mode
dos('C:\Windows\System32\DisplaySwitch.exe /extend');
sca;                    % Clear the screen       
pause(2);
close all;
clearvars;              % Clear the workspace
global stm sys

%% Specify Session Parameters

% Session Timer 
stm.TimerOption =       'simulated';
% stm.TimerOption =       'NI-DAQ';

% Session Type Options
stm.SesOption =         'LCL';  % Localizer
% stm.SesOption =         'RCW';  % Rotating Quarter, Clockwise;
% stm.SesOption =         'RCC';  % Rotating Quarter, CounterClockwise';
% stm.SesOption =         'CPS';  % Center vs Periphery, Sinusoidal

% Session Parameters
stm.SesCycleTime =              20;     % in second
sys.SesCycleNumTotal =          20;     % rep # total
sys.SesCycleNumCurrent =        0;
stm.SesCycleTimeInitial =       tic;

% Display Device
% stm.MonitorName =       'Dell P2416D';
% stm.MonitorDistance =   75;         % in cm
% stm.MonitorHeight =     29.5;       % in cm
% stm.MonitorWidth =      52.7;       % in cm
stm.MonitorName =       'Samsung LG 32GK850F-B';
stm.MonitorDistance =   75;             % in cm
stm.MonitorHeight =     0.02724*1440;	% in cm
stm.MonitorWidth =      0.02724*2560;	% in cm

% Display Dot Parameters
stm.DotDiameter =       0.4;        % in degree
stm.DotMotionSpeedMax =	16;         % in degree / second
stm.DotDensityAngle =   180;        % as how many dots are in the field

%% Setup Timer: NI-DAQ or PC timing
switch stm.TimerOption
    case 'NI-DAQ'
        sys.NIDAQ.D.InTimebaseRate =    100e3;
        sys.NIDAQ.D.CycleSmplHigh =     2;
        sys.NIDAQ.D.CycleSmplLow =      sys.NIDAQ.D.InTimebaseRate * stm.SesCycleTime - ...
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
            @XinStim_Vis_MT_Finder_Callback, 'DAQmx_Val_CounterOutputEvent');
        sys.NIDAQ.TaskCO.start();
    case 'simulated'
        sys.TimerH =                timer;
        sys.TimerH.TimerFcn =       @XinStimEx_Vis_MT_Localizer_Callback;
        sys.TimerH.Period =         stm.SesCycleTime;
        sys.TimerH.TasksToExecute = sys.SesCycleNumTotal+1;
        sys.TimerH.ExecutionMode =  'fixedRate';
        sys.MsgBox =                msgbox('Click to terminate the session after current cycle');
    otherwise
end

%% Prepare the Psychtoolbox window
% Here we call some default settings for setting up Psychtoolbox
                                                PsychDefaultSetup(2);
% Draw to the external screen
screenNumber = 2;
% Define black and white
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);               Screen('Preference', 'SkipSyncTests', 1);
% Open an on screen window
[stm.windowPtr, windowRect] =                   PsychImaging('OpenWindow', screenNumber, black);
% Query: Get the size of the on screen window
[stm.MonitorPixelNumX, stm.MonitorPixelNumY] =  Screen('WindowSize', stm.windowPtr);
% Query: the frame duration
stm.TrialIFI =                                  Screen('GetFlipInterval', stm.windowPtr);
% Querry the max dot size allowed
[~, stm.DotDiameterInPixelMax, ~, ~] =          Screen('DrawDots', stm.windowPtr);

%% Calculate trial parameters
stm.MonitorAngleX =         2*atan(stm.MonitorWidth/2/stm.MonitorDistance)/pi*180;  
stm.MonitorAngleY =         2*atan(stm.MonitorHeight/2/stm.MonitorDistance)/pi*180;
stm.MonitorPixelAngleX =    stm.MonitorAngleX/stm.MonitorPixelNumX;
stm.MonitorPixelAngleY =    stm.MonitorAngleY/stm.MonitorPixelNumY;
stm.MonitorPixelAngle =     mean([stm.MonitorPixelAngleX stm.MonitorPixelAngleY]);
stm.MonitorCenter =         [stm.MonitorPixelNumX/2 stm.MonitorPixelNumY/2];
stm.DotDiameterInPixel =    stm.DotDiameter/stm.MonitorPixelAngle;
if stm.DotDiameterInPixel > stm.DotDiameterInPixelMax
    errordlg('Dot diameter set too big!')
end
stm.DotCenterRadiusMax =    stm.MonitorAngleY/2;
stm.DotVecLength =          stm.DotDensityAngle*1;
stm.DotVecAngle =           rand(1, stm.DotDensityAngle)*360;
stm.DotVecRadius =          rand(1, stm.DotDensityAngle)*stm.DotCenterRadiusMax;
stm.DotVecPositionX =       cos(stm.DotVecAngle/180*pi).*...
                         	(stm.DotVecRadius/stm.MonitorPixelAngleX);
stm.DotVecPositionY =       sin(stm.DotVecAngle/180*pi).*...
                            (stm.DotVecRadius/stm.MonitorPixelAngleY);
stm.DotMotionStepMax =      stm.DotMotionSpeedMax*stm.TrialIFI;
stm.TrialFrameSeq =         1:round(stm.SesCycleTime/stm.TrialIFI);

     
stm.DotMotionPeakTime =     4;    
slope =                     1/(stm.SesCycleTime/2 - stm.DotMotionPeakTime);
shift1 =                    slope*stm.SesCycleTime/2;
shift2 =                    slope*(stm.SesCycleTime/2 - stm.DotMotionPeakTime/2);

Screen('DrawDots', stm.windowPtr, [stm.DotVecPositionX; stm.DotVecPositionY],...
    stm.DotDiameterInPixel, white,	stm.MonitorCenter, 2);
vbl = Screen('Flip', stm.windowPtr);
stm.Running =               1;
        pause;
        sys.TimerH.start;   

%% Play 
while stm.Running
    
    % Session timing
    stm.SesOn =           (   sys.SesCycleNumCurrent>0 && ...
                                    sys.SesCycleNumCurrent<=sys.SesCycleNumTotal);
    stm.SesCycleTimeCurrent =    toc(stm.SesCycleTimeInitial); 
    
    % Estimate current step parameters   
    switch stm.SesOption
        case 'LCL'
            stm.DotMotionSpeedNorm =	stm.SesOn*(...
                    min(1, max(0, shift2-abs(stm.SesCycleTimeCurrent*slope-shift1) ) )...
                                                        );
            stm.DotVecMovingIdx =       1+0*stm.DotVecRadius;
            stm.DotRadiusMinCurrent =   0;
            stm.DotRadiusMaxCurrent =   16;
            stm.DotAngleMinCurrent =    0;
            stm.DotAngleMaxCurrent =    270;
        case 'RCW'
            stm.DotMotionSpeedNorm =    1;
%             stm.DotVecMovingIdx =       1+0*stm.DotVecRadius;
            stm.DotRadiusMinCurrent =   0;
            stm.DotRadiusMaxCurrent =   16;
%             stm.DotAngleMinCurrent =    0;
%             stm.DotAngleMaxCurrent =    360;
        case 'RCC'
            stm.DotMotionSpeedNorm =    1;
%             stm.DotVecMovingIdx =       1+0*stm.DotVecRadius;
            stm.DotRadiusMinCurrent =   0;
            stm.DotRadiusMaxCurrent =   16;
%             stm.DotAngleMinCurrent =    0;
%             stm.DotAngleMaxCurrent =    360;
        case 'CPS'
            stm.DotMotionSpeedNorm =    1;
%             stm.DotVecMovingIdx =       1+0*stm.DotVecRadius;
%             stm.DotRadiusMinCurrent =   0;
%             stm.DotRadiusMaxCurrent =   16;
            stm.DotAngleMinCurrent =    0;
            stm.DotAngleMaxCurrent =    360;
        otherwise
    end
    
    % Move the dots radially: move the ones on the DocVecMovingIdx, with DotMotionStepCurrent
    stm.DotMotionStepCurrent =  stm.DotMotionSpeedNorm*stm.DotMotionStepMax*stm.DotVecMovingIdx;
    stm.DotVecRadius =          stm.DotVecRadius + stm.DotMotionStepCurrent;

    % Replace the missing dots
    stm.DotVecIndexOut =        stm.DotVecRadius > stm.DotRadiusMaxCurrent;                       
    stm.DotVecRadius(stm.DotVecIndexOut) = ...
                                stm.DotRadiusMinCurrent; 
    stm.DotVecAngle(stm.DotVecIndexOut) = ...
                                ( stm.DotAngleMinCurrent + ...
                               	(stm.DotAngleMaxCurrent-stm.DotAngleMinCurrent)*...
                                rand(1,stm.DotVecLength) ).*stm.DotVecIndexOut;    
    
    % Translate the display coordinates
    stm.DotVecPositionX =       cos(stm.DotVecAngle/180*pi).*...
                                (stm.DotVecRadius/stm.MonitorPixelAngle);
    stm.DotVecPositionY =       sin(stm.DotVecAngle/180*pi).*...
                                (stm.DotVecRadius/stm.MonitorPixelAngle);

    %% Display 
    Screen('DrawDots', stm.windowPtr, [stm.DotVecPositionX; stm.DotVecPositionY],...
        stm.DotDiameterInPixel, white,	stm.MonitorCenter, 2);      % dots
    Screen('DrawingFinished', stm.windowPtr);                       % hold
    vbl = Screen('Flip', stm.windowPtr, vbl + 0.5*stm.TrialIFI);    % flip
    
    %% if
end

%% Clear the display
% if sys.SesCycleNumCurrent < sys.SesCycleNumTotal + 1 
%     % interrupted, but not naturally finished
%     sys.SesCycleNumCurrent = sys.SesCycleNumTotal;
%     XinStimEx_Vis_MT_Localizer_Callback;
% end
pause(2);
sca;
% dos('C:\Windows\System32\DisplaySwitch.exe /clone');