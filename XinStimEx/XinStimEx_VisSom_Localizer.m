%% MT localizer with multiple options

%% Switch multi-display mode
% for triple monitor @190925, #1=Outside Right, #2=Inside, #3=Outside Main.
% "extend" should be set on triple screens before openning the current Matlab
% dos('C:\Windows\System32\DisplaySwitch.exe /extend');
sca;                    % Clear the screen       
clearvars;              % Clear the workspace
pause(2);
global stm sys

stm.SR =                100e3;
stm.SesDurTotal =       396;                                
                                %   F:Face;	B:Body;     O:Object;
                                %   P:Phase scambled;   S:Spatial scambled
stm.Vis.SesOptionMore = 0;  stm.Vis.SesOptionContrast = 'All';	% Dots
% stm.Vis.SesOptionMore = 1;  stm.Vis.SesOptionContrast = 'BvF';	% Body vs Face
% stm.Vis.SesOptionMore = 1;  stm.Vis.SesOptionContrast = 'OvF';  % Object vs Face
% stm.Vis.SesOptionMore = 1;  stm.Vis.SesOptionContrast = 'PvF';  % Phase SCRBD Face vs Face 
% stm.Vis.SesOptionMore = 1;  stm.Vis.SesOptionContrast = 'SvF';  % Spatial SCRBD Face vs Face 
% stm.Vis.SesOptionMore = 1;  stm.Vis.SesOptionContrast = 'OvB';  % Object vs Body

%% Somatosensory DO parameters
stm.Som.CycleDurTotal =         22;
stm.Som.CycleNumTotal =         stm.SesDurTotal/stm.Som.CycleDurTotal;
stm.Som.TrialPreStimTime =      0;
stm.Som.TrialStimTime =         stm.Som.CycleDurTotal;
stm.Som.TrialStimChanNum =      11;
stm.Som.TrialPuffSeqTime =      2.0;
% stm.Som.TrialStimChanBitSeq =   [2 2 2 2 6 6 6 2 2 2 2];
% stm.Som.TrialStimChanBitSeq =   [5 5 5 5 6 6 6 5 5 5 5];
% stm.Som.TrialStimChanBitSeq =   [4 4 4 4 6 6 6 4 4 4 4];
stm.Som.TrialStimChanBitSeq =   [4 4 4 4 0 0 0 4 4 4 4];
% stm.Som.TrialStimChanBitSeq =   [2 2 2 6 2 2 2 2];

stm.Som.TrialPuffFreq =         10;
stm.Som.TrialPuffDutyCycle =	0.5;

%% Synthesize the DO sequence
    stm.Som.SmplNumTrialPreStim =	round(stm.SR*stm.Som.TrialPreStimTime); 
    stm.Som.PuffNum =               	  stm.Som.TrialPuffSeqTime*stm.Som.TrialPuffFreq;
    stm.Som.SmplNumPuffOn =         round(stm.SR/stm.Som.TrialPuffFreq*   stm.Som.TrialPuffDutyCycle);
    stm.Som.SmplNumPuffOff =        round(stm.SR/stm.Som.TrialPuffFreq*(1-stm.Som.TrialPuffDutyCycle));
    stm.Som.SmplNumPostPuff =       round(stm.SR*(stm.Som.TrialStimTime/stm.Som.TrialStimChanNum - stm.Som.TrialPuffSeqTime));
    stm.Som.SmplNumTrialPostStim =	round(stm.SR* (stm.Som.CycleDurTotal-stm.Som.TrialPreStimTime-stm.Som.TrialStimTime) );
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
    % Finalize the DO Sequence
    if length(stm.Som.seq)~= stm.SR*stm.Som.CycleDurTotal
        errordlg('length not right');
        return
    end
    % plot(stm.Som.seq);
    stm.Som.seq = uint32(stm.Som.seq);

%% Visual CO Parameters

% Session Timer 
stm.Vis.SesOption =         'DLCLF';  % Dot Localizer

stm.Vis.CycleDurTotal =         18;     % in second
stm.Vis.CycleNumTotal =         stm.SesDurTotal/stm.Vis.CycleDurTotal;     % rep # total
stm.Vis.CycleNumCurrent =       0;
stm.Vis.CycleDurCurrentTimer =	tic;

% Display Device
stm.Vis.MonitorName =       'LG 32GK850F-B';
stm.Vis.MonitorDistance =   75;             % in cm
stm.Vis.MonitorHeight =     0.02724*1440;	% in cm
stm.Vis.MonitorWidth =      0.02724*2560;	% in cm

%% Prepare the Psychtoolbox window
% Here we call some default settings for setting up Psychtoolbox
                                                PsychDefaultSetup(2);
% Draw to the external screen
% for triple monitor @190925, #1=Outside Right, #2=Inside, #3=Outside Main.
% for triple monitor @190925, #1=Outside Right, #2=Outside Main #3=Inside.
% screenNumber = 1;
screenNumber = 2;
% screenNumber = 3;

% Define shades
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);   
gray =  GrayIndex(screenNumber, 0.5);   
                                                Screen('Preference', 'VisualDebugLevel', 1);
                                                Screen('Preference', 'SkipSyncTests', 1);
% Open an on screen window
[stm.Vis.windowPtr, windowRect] =               PsychImaging('OpenWindow', screenNumber, black);
% Query: Get the size of the on screen window
[stm.Vis.MonitorPixelNumX, stm.Vis.MonitorPixelNumY] = ...
                                                Screen('WindowSize', stm.Vis.windowPtr);
% Query: the frame duration
stm.Vis.TrialIFI =                              Screen('GetFlipInterval', stm.Vis.windowPtr);
if abs(stm.Vis.TrialIFI - 1/144)/(1/144) > 0.05
    errordlg('screen is not at right refresh rate!');
    return;
end
% Querry the max dot size allowed
[~, stm.Vis.DotDiameterInPixelMax, ~, ~] =      Screen('DrawDots', stm.Vis.windowPtr);

%% Initialize parameters
switch stm.Vis.SesOption(1)
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
        stm.Vis.TrialFrameSeq =         1:round(stm.Vis.CycleDurTotal/stm.Vis.TrialIFI);
        switch stm.Vis.SesOption(2:4)
            case 'LCL'
                stm.Vis.DotMotionPeakTime =     4;    
                slope =                     1/(stm.Vis.CycleDurTotal/2 - stm.Vis.DotMotionPeakTime);
                shift1 =                    slope*stm.Vis.CycleDurTotal/2;
                shift2 =                    slope*(stm.Vis.CycleDurTotal/2 - stm.Vis.DotMotionPeakTime/2);
        end        
        if length(stm.Vis.SesOption)>4
            if stm.Vis.SesOption(5) == 'F'
                % read in texture patches
                stm.Vis.TexImDir =	'D:\GitHub\EyeTrackerCalibration\facephase\Wang\phase_stimuli\';
                for i = 1:20
                    stm.Vis.TexImFaceOri{i} =	imread([stm.Vis.TexImDir 'm'  num2str(i) '.png']);
                    stm.Vis.TexImFacePhs{i} =	imread([stm.Vis.TexImDir 'mp' num2str(i) '.png']);
                    stm.Vis.TexImFaceSpt{i} =	imread([stm.Vis.TexImDir 'ms' num2str(i) '.png']);
                    stm.Vis.TexImBodyPrt{i} =	imread([stm.Vis.TexImDir 'b'  num2str(i) '.png']);
                    stm.Vis.TexImObjects{i} =	imread([stm.Vis.TexImDir 'h'  num2str(i) '.png']);
                    stm.Vis.TexInd(i,1) =	Screen('MakeTexture', stm.Vis.windowPtr, stm.Vis.TexImFaceOri{i}); % F:1
                    stm.Vis.TexInd(i,2) =	Screen('MakeTexture', stm.Vis.windowPtr, stm.Vis.TexImFacePhs{i}); % P:2
                    stm.Vis.TexInd(i,3) =	Screen('MakeTexture', stm.Vis.windowPtr, stm.Vis.TexImFaceSpt{i}); % S:3
                    stm.Vis.TexInd(i,4) =	Screen('MakeTexture', stm.Vis.windowPtr, stm.Vis.TexImBodyPrt{i}); % B:4
                    stm.Vis.TexInd(i,5) =	Screen('MakeTexture', stm.Vis.windowPtr, stm.Vis.TexImObjects{i}); % O:5
                end
                % pre-arrange image sequence
                stm.Vis.TexIdxCurrent =     1;  
                        stm.Vis.TexIdxAll =             [];
                for i = 1:stm.Vis.CycleNumTotal
                    for j = 1:3
                        stm.Vis.TexIdxAll(i, j, :) =    randperm(20, 6);
                    end
                end
                stm.Vis.TexIdxAll =     stm.Vis.TexIdxAll(:,[1 1 1 2 3],:);
                switch stm.Vis.SesOptionContrast
                    case 'All'
                        stm.Vis.TexTocTime =    stm.Vis.CycleDurTotal/10;   % 10 images / trial
                        stm.Vis.TexSeq =    [   3   3   4   4   1   1   5   5   2   2;...
                                                1   2   1   2   1   2   1   2   1   2];
                    case 'BvF'
                        stm.Vis.TexTocTime =    stm.Vis.CycleDurTotal/12;   % 12 images / trial
                        stm.Vis.TexSeq =    [   4   4   4   1   1   1   1   1   1   4   4   4;...
                                                1   2   3   1   2   3   4   5   6   4   5   6];
                    case 'OvF'
                        stm.Vis.TexTocTime =    stm.Vis.CycleDurTotal/12;   % 12 images / trial
                        stm.Vis.TexSeq =    [   5   5   5   1   1   1   1   1   1   5   5   5;...
                                                1   2   3   1   2   3   4   5   6   4   5   6];
                    case 'PvF'
                        stm.Vis.TexTocTime =    stm.Vis.CycleDurTotal/12;   % 12 images / trial
                        stm.Vis.TexSeq =    [   2   2   2   1   1   1   1   1   1   2   2   2;...
                                                1   2   3   1   2   3   4   5   6   4   5   6];
                    case 'SvF'
                        stm.Vis.TexTocTime =    stm.Vis.CycleDurTotal/12;   % 12 images / trial
                        stm.Vis.TexSeq =    [   3   3   3   1   1   1   1   1   1   3   3   3;...
                                                1   2   3   1   2   3   4   5   6   4   5   6];
                    case 'OvB'
                        stm.Vis.TexTocTime =    stm.Vis.CycleDurTotal/12;   % 12 images / trial
                        stm.Vis.TexSeq =    [   5   5   5   4   4   4   4   4   4   5   5   5;...
                                                1   2   3   1   2   3   4   5   6   4   5   6];
                    otherwise
                end
            end
        end
        Screen('DrawDots', stm.Vis.windowPtr, [stm.Vis.DotVecPositionX; stm.Vis.DotVecPositionY],...
            stm.Vis.DotDiameterInPixel, white,	stm.Vis.MonitorCenter, 2);
        vbl = Screen('Flip', stm.Vis.windowPtr);
    otherwise
end

%% NI-DAQ
sys.NIDAQ.D.InTimebaseRate =    stm.SR;
sys.NIDAQ.D.CycleSmplHigh =     2;
sys.NIDAQ.D.CycleSmplLow =      sys.NIDAQ.D.InTimebaseRate * stm.Vis.CycleDurTotal - ...
                                sys.NIDAQ.D.CycleSmplHigh;
import dabs.ni.daqmx.*
sys.NIDAQ.TaskCO = Task('Recording Session Cycle Switcher3');
sys.NIDAQ.TaskCO.createCOPulseChanTicks(...
    'Dev3', 1, 'Cycle Counter', '100kHzTimebase', ...
    sys.NIDAQ.D.CycleSmplLow, sys.NIDAQ.D.CycleSmplHigh,...
    0, 'DAQmx_Val_Low');
sys.NIDAQ.TaskCO.cfgImplicitTiming(...
    'DAQmx_Val_FiniteSamps',	stm.Vis.CycleNumTotal+1);
sys.NIDAQ.TaskCO.cfgDigEdgeStartTrig(...
    'RTSI6',            'DAQmx_Val_Rising');
sys.NIDAQ.TaskCO.registerSignalEvent(...
    @XinStimEx_VisSom_Localizer_Callback, 'DAQmx_Val_CounterOutputEvent');
sys.NIDAQ.TaskCO.start()

sys.NIDAQ.TaskDO = Task('Cochlear Implant Trigger Sequence3');
sys.NIDAQ.TaskDO.createDOChan(...
    'Dev3',     'port0/line0:7');
sys.NIDAQ.TaskDO.cfgSampClkTiming(...
    stm.SR,     'DAQmx_Val_ContSamps',	stm.Som.CycleDurTotal*stm.SR);
sys.NIDAQ.TaskDO.cfgDigEdgeStartTrig(... 
    'RTSI6',	'DAQmx_Val_Rising');
% sys.NIDAQ.TaskDO.registerEveryNSamplesEvent(...
% 	@XinStimEx_VisSom_Localizer_Callback,	stm.SR*stm.Vis.CycleDurTotal,...
% 	true,       'native');  
% The 'everyNSamplesReadDataTypeOption' property can only be set to a value for input Tasks
sys.NIDAQ.TaskDO.writeDigitalData(      stm.Som.seq);
sys.NIDAQ.TaskDO.start()

stm.Vis.Running =               1; 
sys.MsgBox =        msgbox('Click to terminate the session after current visual cycle');

%% Play 
while stm.Vis.Running
    
    % Session timing
    stm.Vis.SesOn =           (   stm.Vis.CycleNumCurrent>0 && ...
                                    stm.Vis.CycleNumCurrent<=stm.Vis.CycleNumTotal);
    stm.Vis.CycleDurTotalCurrent =    toc(stm.Vis.CycleDurCurrentTimer); 
    
    % Estimate current dot step parameters   
    if stm.Vis.SesOption(1)=='D'
        switch stm.Vis.SesOption(2:4)
            case 'LCL'
                if stm.Vis.SesOptionMore
                    stm.Vis.DotMotionSpeedNorm = 0;
                else
                    stm.Vis.DotMotionSpeedNorm =	stm.Vis.SesOn*(...
                            min(1, max(0, shift2-abs(stm.Vis.CycleDurTotalCurrent*slope-shift1) ) )...
                                                                );
                end
                        
                stm.Vis.DotRadiusMinCurrent =   0;
                stm.Vis.DotRadiusMaxCurrent =   stm.Vis.MonitorAngleY/2;
                stm.Vis.DotAngleMinCurrent =    0;
                stm.Vis.DotAngleMaxCurrent =    360;
                stm.Vis.DotVecMovingIdx =       1+0*stm.Vis.DotVecRadius;
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
            stm.Vis.DotRadiusMaskerMinCurrent =   (cos(2*pi*stm.Vis.CycleDurTotalCurrent/stm.Vis.CycleDurTotal)+1)/2 * stm.Vis.DotAngleDivide/2;
            stm.Vis.DotRadiusMaskerMaxCurrent =   (cos(2*pi*stm.Vis.CycleDurTotalCurrent/stm.Vis.CycleDurTotal)+1)/2 * stm.Vis.MonitorAngleY/2 + ... 
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
        if length(stm.Vis.SesOption)>4 && stm.Vis.SesOn
            if stm.Vis.SesOption(5) == 'F'
                a = stm.Vis.TexIdxCurrent;
                stm.Vis.TexIdxCurrent =	...
                    min(ceil(stm.Vis.CycleDurTotalCurrent/stm.Vis.TexTocTime), length(stm.Vis.TexSeq));
                if a~= stm.Vis.TexIdxCurrent
                    disp([sprintf('frame time:   '), datestr(now, 'HH:MM:SS.FFF')]);
                end
                if stm.Vis.SesOptionMore
                    Screen('DrawTextures', stm.Vis.windowPtr,...
                        stm.Vis.TexInd(...
                            stm.Vis.TexIdxAll(...
                                stm.Vis.CycleNumCurrent,...
                                stm.Vis.TexSeq(1, stm.Vis.TexIdxCurrent),...
                                stm.Vis.TexSeq(2, stm.Vis.TexIdxCurrent) ),...
                            stm.Vis.TexSeq(1, stm.Vis.TexIdxCurrent)        ),...
                        [], (stm.Vis.MonitorCenter([1 2 1 2]) + 240* [1 -1 -1 1])');
                else
                    Screen('DrawTextures', stm.Vis.windowPtr,...
                        stm.Vis.TexInd(...
                            stm.Vis.TexIdxAll(...
                                stm.Vis.CycleNumCurrent,...
                                stm.Vis.TexSeq(1, stm.Vis.TexIdxCurrent),...
                                stm.Vis.TexSeq(2, stm.Vis.TexIdxCurrent) ),...
                            stm.Vis.TexSeq(1, stm.Vis.TexIdxCurrent)        ),...
                        [], (stm.Vis.MonitorCenter([1 2 1 2]) + 10*[1 -1 -1 1])');
                end
                    
            end
        end                                                             % face (center attractor)
        Screen('DrawingFinished', stm.Vis.windowPtr);                       % hold
        vbl = Screen('Flip', stm.Vis.windowPtr, vbl + 0.5*stm.Vis.TrialIFI);    % flip
    else
        pause(0.1);
    end
end

%% Clean up
pause(0.025);
% sys.NIDAQ.TaskDO.
sys.NIDAQ.TaskDO.abort();
sys.NIDAQ.TaskDO.delete;
        try sys.MsgBox.delete();    catch
        end
sca;
% dos('C:\Windows\System32\DisplaySwitch.exe /clone');