sca

dos('C:\Windows\System32\DisplaySwitch.exe /extend');
pause(2);

%% MT Finder Demo
% Clear the workspace and the screen
sca;
close all;
clearvars;
global stm sys

%% Stimuli perimeters
stm.MonitorDistance =   75;         % in cm
stm.MonitorHeight =     29.5;       % in cm
stm.MonitorWidth =      52.7;       % in cm
stm.MonitorName =       'Dell P2416D';
stm.DotDiameter =       0.4;        % in degree
stm.DotMotionSpeedMax =	16;         % in degree / second
stm.DotDensityAngle =   180;         % as how many dots are in the field
stm.TrialDuration =     20;         % in second

%% Setup NI-DAQ
sys.Ses.CycleTime =             20;
sys.Ses.CycleNumTotal =         20;
sys.Ses.CycleNumCurrent =       0;
sys.Ses.CycleInitialTime =      tic;

sys.NIDAQ.D.InTimebaseRate =    100e3;
sys.NIDAQ.D.CycleSmplHigh =     2;
sys.NIDAQ.D.CycleSmplLow =      sys.NIDAQ.D.InTimebaseRate * sys.Ses.CycleTime - ...
                                sys.NIDAQ.D.CycleSmplHigh;
import dabs.ni.daqmx.*

% sys.NIDAQ.dev = Device('Dev1');
% sys.NIDAQ.dev.reset();
% sys.NIDAQ.TaskCO = Task('Recording Session Cycle Switcher');
% sys.NIDAQ.TaskCO.createCOPulseChanTicks(...
%     'Dev1', 0, 'Cycle Counter', 'RTSI7', ...
%     sys.NIDAQ.D.CycleCOStateSmpl, sys.NIDAQ.D.CycleCOStateSmpl,...
%     0, 'DAQmx_Val_Low');
% sys.NIDAQ.TaskCO.cfgImplicitTiming(...
%     'DAQmx_Val_FiniteSamps',	round(sys.Ses.CycleNumTotal/2)+1);
% sys.NIDAQ.TaskCO.cfgDigEdgeStartTrig(...
% 	'RTSI6',            'DAQmx_Val_Falling');
% % 	'RTSI6',            'DAQmx_Val_Rising');
% sys.NIDAQ.TaskCO.registerSignalEvent(...
% 	@Visual_MT_Finder_Demo_Callback, 'DAQmx_Val_CounterOutputEvent');
% sys.NIDAQ.TaskCO.start();

sys.NIDAQ.TaskCO = Task('Recording Session Cycle Switcher');
sys.NIDAQ.TaskCO.createCOPulseChanTicks(...
    'Dev3', 1, 'Cycle Counter', '100kHzTimebase', ...
    sys.NIDAQ.D.CycleSmplLow, sys.NIDAQ.D.CycleSmplHigh,...
    0, 'DAQmx_Val_Low');
sys.NIDAQ.TaskCO.cfgImplicitTiming(...
    'DAQmx_Val_FiniteSamps',	sys.Ses.CycleNumTotal+1);
sys.NIDAQ.TaskCO.cfgDigEdgeStartTrig(...
	'RTSI6',            'DAQmx_Val_Rising');
sys.NIDAQ.TaskCO.registerSignalEvent(...
	@XinStim_Vis_MT_Finder_Callback, 'DAQmx_Val_CounterOutputEvent');
sys.NIDAQ.TaskCO.start();

%% Prepare the PTB window

% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% Draw to the external screen
screenNumber = 1;

% Define black and white
% white = WhiteIndex(screenNumber);
% black = BlackIndex(screenNumber);
white = 1;
black = 0;

Screen('Preference', 'SkipSyncTests', 1);

% Open an on screen window
[stm.windowPtr, windowRect] = PsychImaging('OpenWindow', screenNumber, black);

%% Querries
% Get the size of the on screen window
[stm.MonitorPixelNumX, stm.MonitorPixelNumY] = Screen('WindowSize', stm.windowPtr);
% Query the frame duration
stm.TrialIFI = Screen('GetFlipInterval', stm.windowPtr);
% Querry the max dot size allowed
[~, stm.DotDiameterInPixelMax, ~, ~] = Screen('DrawDots', stm.windowPtr);

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
stm.DotMotionStep =         stm.DotMotionSpeedMax*stm.TrialIFI;
stm.TrialFrameSeq =         1:round(stm.TrialDuration/stm.TrialIFI);
Screen('DrawDots', stm.windowPtr, [stm.DotVecPositionX; stm.DotVecPositionY],...
    stm.DotDiameterInPixel, white,	stm.MonitorCenter, 2);
vbl = Screen('Flip', stm.windowPtr);

stm.Running =               1;
stm.DotMotionPeakTime =     4;    
slope =                     1/(sys.Ses.CycleTime/2 - stm.DotMotionPeakTime);
shift1 =                    slope*sys.Ses.CycleTime/2;
shift2 =                    slope*(sys.Ses.CycleTime/2 - stm.DotMotionPeakTime/2);

%% Play 
while stm.Running
    
    % Estimate current speed
    stm.DotMotionOn =           (   sys.Ses.CycleNumCurrent>0 && ...
                                    sys.Ses.CycleNumCurrent<=sys.Ses.CycleNumTotal);
    stm.DotMotionTrialTime =    toc(sys.Ses.CycleInitialTime);
    stm.DotMotionSpeedNorm =	stm.DotMotionOn*(...
            min(1, max(0, shift2-abs(stm.DotMotionTrialTime*slope-shift1) ) )...
                                                );
%     stm.DotMotionSpeedNorm =	stm.DotMotionOn*(...
%             1- ( abs(stm.DotMotionTrialTime/(sys.Ses.CycleTime/2)-1) )...
%                                                 );          
    % Move the dots
    stm.DotVecRadius =          stm.DotVecRadius + stm.DotMotionSpeedNorm*stm.DotMotionStep;

    % Replace the missing dots
    stm.DotVecIndexOut =        abs(stm.DotVecPositionX)>stm.MonitorPixelNumX/2 | ...
                                abs(stm.DotVecPositionY)>stm.MonitorPixelNumY/2;
    stm.DotVecIndexIn =         ~stm.DotVecIndexOut;                             
    stm.DotVecRadius =          stm.DotVecRadius                .*stm.DotVecIndexIn + ...
                                zeros(1,stm.DotVecLength)       .*stm.DotVecIndexOut; 
    stm.DotVecAngle =           stm.DotVecAngle                 .*stm.DotVecIndexIn + ...
                                rand(1,stm.DotVecLength)*360	.*stm.DotVecIndexOut;    
    % Translate the display coordinates
    stm.DotVecPositionX =       cos(stm.DotVecAngle/180*pi).*...
                                (stm.DotVecRadius/stm.MonitorPixelAngleX);
    stm.DotVecPositionY =       sin(stm.DotVecAngle/180*pi).*...
                                (stm.DotVecRadius/stm.MonitorPixelAngleY);

    %% Display the dot pattern
    Screen('DrawDots', stm.windowPtr, [stm.DotVecPositionX; stm.DotVecPositionY],...
        stm.DotDiameterInPixel, white,	stm.MonitorCenter, 2);
        Screen('DrawingFinished', stm.windowPtr);
    vbl = Screen('Flip', stm.windowPtr, vbl + 0.5*stm.TrialIFI); 
    
    %% if
end

pause(2);
sca;
dos('C:\Windows\System32\DisplaySwitch.exe /clone');