%% MT localizer with multiple options

%% Switch multi-display mode
if max(Screen('Screens')) ~=2
    opts = struct(  'WindowStyle',  'modal',... 
                    'Interpreter',  'tex');
    errordlg(...
        [   '\fontsize{20} The monitors are not in all extended mode \newline ',...
            'Close thecurrent Matlab \newline',...
            'Extend all screens in windows \newline' ,...
            'And restart Matlab'],...
        '', opts)
    return
else
    
end
dos('C:\Windows\System32\DisplaySwitch.exe /extend');
sca;                    % Clear the screen       
pause(2);
% close all;
clearvars;              % Clear the workspace
global stm sys

%% Specify Session Parameters
stm.Vis.SesTime =  datestr(now, 30);
% locate the screen number
for i = 1: max(Screen('Screens'))
    info = Screen('Resolution', i);
    if info.hz ==144
        sys.screenNumber = i;
        break
    end
end

stm.SR =                100e3;
stm.SesDurTotal =       400;                                
% stm.Vis.PicSource = '\Wang\phase_stimuli';
% stm.Vis.PicSource = '\Hung\phase_stimuli';
% stm.Vis.PicSource = '\P002\equalized';
% stm.Vis.PicSource = '\P002\pink2_fullscreen';
% stm.Vis.PicSource = '\P002\pink_song_pattern';
% stm.Vis.PicSource = '\P002\pink_song_shifthalf';
stm.Vis.PicSource = '\Last\shifthalf';

% stm.Vis.PicBackground = 'white';
stm.Vis.PicBackground = 'gray';
stm.Vis.PicDur =        0.5;

                                %   F:Face;	B:Body;     O:Object;
                                %   P:Phase scambled;   S:Spatial scambled

stm.Vis.SesOptionContrast = 'AvF';  % Animals               vs Faces
% stm.Vis.SesOptionContrast = 'VvF';  % Fruits & Vegetables	vs Faces
% stm.Vis.SesOptionContrast = 'OvF';  % Familiar Objects  	vs Faces
% stm.Vis.SesOptionContrast = 'UvF';  % Unfamiliar Objects  	vs Faces
% stm.Vis.SesOptionContrast = 'BvF';	% Body Parts            vs Faces
% stm.Vis.SesOptionContrast = 'PvF';  % Phase SCRBD Faces     vs Faces 
% stm.Vis.SesOptionContrast = 'SvF';  % Spatial SCRBD Faces   vs Faces 

% stm.Vis.SesOptionContrast = 'BvF';	% Body Parts            vs Faces
% stm.Vis.SesOptionContrast = 'OvF';  % Familiar Objects      vs Faces
% stm.Vis.SesOptionContrast = 'PvF';  % Phase SCRBD Faces     vs Faces 
% stm.Vis.SesOptionContrast = 'SvF';  % Spatial SCRBD Faces   vs Faces 
% stm.Vis.SesOptionContrast = 'OvB';  % Familiar Object       vs Body



%% Visual CO Parameters
% Session Timer 
stm.Vis.CycleDurTotal =         20;     % in second
stm.Vis.CycleNumTotal =         stm.SesDurTotal/stm.Vis.CycleDurTotal;     % rep # total
stm.Vis.CycleNumCurrent =       0;
stm.Vis.CycleDurCurrentTimer =	tic;
stm.Vis.CyclePicNum =           round(stm.Vis.CycleDurTotal/2/stm.Vis.PicDur);
stm.Vis.CyclePicNumHf =         round(stm.Vis.CyclePicNum/2);

% Display Device
stm.Vis.MonitorName =       'LG 32GK850F-B';
stm.Vis.MonitorDistance =   75;             % in cm
stm.Vis.MonitorHeight =     0.02724*1440;	% in cm
stm.Vis.MonitorWidth =      0.02724*2560;	% in cm

%% Prepare the Psychtoolbox window
% Here we call some default settings for setting up Psychtoolbox
                                                PsychDefaultSetup(2);
% Define shades
white = WhiteIndex(sys.screenNumber);
black = BlackIndex(sys.screenNumber);   
gray =  GrayIndex(sys.screenNumber, 0.5);   
                                                Screen('Preference', 'VisualDebugLevel', 1);
                                                Screen('Preference', 'SkipSyncTests', 1);
% Open an on screen window
switch stm.Vis.PicBackground
    case 'white';	[stm.Vis.windowPtr, windowRect] = PsychImaging('OpenWindow', sys.screenNumber, white);
    case 'black';	[stm.Vis.windowPtr, windowRect] = PsychImaging('OpenWindow', sys.screenNumber, black);
    case 'gray';    [stm.Vis.windowPtr, windowRect] = PsychImaging('OpenWindow', sys.screenNumber, gray);
end
% Query: Get the size of the on screen window
[stm.Vis.MonitorPixelNumX, stm.Vis.MonitorPixelNumY] = ...
                                                Screen('WindowSize', stm.Vis.windowPtr);
% Query: the frame duration
stm.Vis.TrialIFI =                              Screen('GetFlipInterval', stm.Vis.windowPtr);
if abs(stm.Vis.TrialIFI - 1/144)/(1/144) > 0.05
    errordlg('screen is not at right refresh rate!');
    return;
end
vbl = Screen('Flip', stm.Vis.windowPtr);

%% Initialize parameters
stm.Vis.MonitorAngleX =         2*atan(stm.Vis.MonitorWidth/2/stm.Vis.MonitorDistance)/pi*180;  
stm.Vis.MonitorAngleY =         2*atan(stm.Vis.MonitorHeight/2/stm.Vis.MonitorDistance)/pi*180;
stm.Vis.MonitorPixelAngleX =    stm.Vis.MonitorAngleX/stm.Vis.MonitorPixelNumX;
stm.Vis.MonitorPixelAngleY =    stm.Vis.MonitorAngleY/stm.Vis.MonitorPixelNumY;
stm.Vis.MonitorPixelAngle =     mean([stm.Vis.MonitorPixelAngleX stm.Vis.MonitorPixelAngleY]);
stm.Vis.MonitorCenter =         [stm.Vis.MonitorPixelNumX/2 stm.Vis.MonitorPixelNumY/2];

% texture patch display size
switch stm.Vis.PicSource
    case '\Wang\phase_stimuli';         stm.Vis.MonitorTexPatchPos = 240* [1 -1 -1 1];
    case '\Hung\phase_stimuli';         stm.Vis.MonitorTexPatchPos = [250 -150 -250 150];
    case '\P002\equalized';             stm.Vis.MonitorTexPatchPos = [300 -180 -300 180];            
    case '\P002\pink2_fullscreen';      stm.Vis.MonitorTexPatchPos = [1280 -720 -1280 720];      
    case '\P002\pink_song_pattern';     stm.Vis.MonitorTexPatchPos = [1280 -720 -1280 720];    
    case '\P002\pink_song_shifthalf';	stm.Vis.MonitorTexPatchPos = [1280 -720 -1280 720];   
    case '\Last\shifthalf';             stm.Vis.MonitorTexPatchPos = [1280 -720 -1280 720]; 
    otherwise;                          stm.Vis.MonitorTexPatchPos = 10*[1 -1 -1 1];
end
     
% read in texture patches
stm.Vis.TexImDir =	['D:\GitHub\EyeTrackerCalibration\facephase', stm.Vis.PicSource, '\'];
for i = 1:20
    if strcmp(stm.Vis.PicSource(1:5), '\P002') || strcmp(stm.Vis.PicSource(1:5), '\Last')   
        stm.Vis.TexImFaceOri{i} =	imread([stm.Vis.TexImDir 'SHINEd_m'  num2str(i) '.tif']);
        stm.Vis.TexImAnimals{i} =	imread([stm.Vis.TexImDir 'SHINEd_a'  num2str(i) '.tif']);
        stm.Vis.TexImFruitVe{i} =	imread([stm.Vis.TexImDir 'SHINEd_f'  num2str(i) '.tif']);
        stm.Vis.TexImObjFami{i} =	imread([stm.Vis.TexImDir 'SHINEd_o'  num2str(i) '.tif']);
        stm.Vis.TexImObjUnfm{i} =	imread([stm.Vis.TexImDir 'SHINEd_u'  num2str(i) '.tif']);
        stm.Vis.TexImBodyPrt{i} =	imread([stm.Vis.TexImDir 'SHINEd_b'  num2str(i) '.tif']);
        stm.Vis.TexInd(i,1) =	Screen('MakeTexture', stm.Vis.windowPtr, stm.Vis.TexImFaceOri{i}); % 1: Face, Frontal
        stm.Vis.TexInd(i,2) =	Screen('MakeTexture', stm.Vis.windowPtr, stm.Vis.TexImAnimals{i}); % 2: Animals
        stm.Vis.TexInd(i,3) =	Screen('MakeTexture', stm.Vis.windowPtr, stm.Vis.TexImFruitVe{i}); % 3: Fruits & Vegetables
        stm.Vis.TexInd(i,4) =	Screen('MakeTexture', stm.Vis.windowPtr, stm.Vis.TexImObjFami{i}); % 4: Objects, Familiar
        stm.Vis.TexInd(i,5) =	Screen('MakeTexture', stm.Vis.windowPtr, stm.Vis.TexImObjUnfm{i}); % 5: Objects, Unfamiliar 
        stm.Vis.TexInd(i,6) =	Screen('MakeTexture', stm.Vis.windowPtr, stm.Vis.TexImBodyPrt{i}); % 6: Body Parts        
    else
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
end
    % pre-arrange image sequence
    stm.Vis.TexIdxCurrent =     0;  
	stm.Vis.TexIdxAll =         [];
    for i = 1:stm.Vis.CycleNumTotal
        for j = 1:size(stm.Vis.TexInd, 2)
            stm.Vis.TexIdxAll(i, j, :) =    randperm(20, stm.Vis.CyclePicNum);
        end
    end
    if strcmp(stm.Vis.PicSource(1:5), '\P002') || strcmp(stm.Vis.PicSource(1:5), '\Last')          
        switch stm.Vis.SesOptionContrast
            case 'AvF';	stm.Vis.TexSeq = [ 2*ones(1,stm.Vis.CyclePicNumHf) 1*ones(1,stm.Vis.CyclePicNum) 2*ones(1,stm.Vis.CyclePicNumHf)];
            case 'VvF';	stm.Vis.TexSeq = [ 3*ones(1,stm.Vis.CyclePicNumHf) 1*ones(1,stm.Vis.CyclePicNum) 3*ones(1,stm.Vis.CyclePicNumHf)];
            case 'OvF';	stm.Vis.TexSeq = [ 4*ones(1,stm.Vis.CyclePicNumHf) 1*ones(1,stm.Vis.CyclePicNum) 4*ones(1,stm.Vis.CyclePicNumHf)];
            case 'UvF';	stm.Vis.TexSeq = [ 5*ones(1,stm.Vis.CyclePicNumHf) 1*ones(1,stm.Vis.CyclePicNum) 5*ones(1,stm.Vis.CyclePicNumHf)];
            case 'BvF';	stm.Vis.TexSeq = [ 6*ones(1,stm.Vis.CyclePicNumHf) 1*ones(1,stm.Vis.CyclePicNum) 6*ones(1,stm.Vis.CyclePicNumHf)];
            otherwise
        end       
    else
        stm.Vis.TexIdxAll =     stm.Vis.TexIdxAll(:,[1 1 1 2 3],:);
        switch stm.Vis.SesOptionContrast
            case 'PvF';	stm.Vis.TexSeq = [ 2*ones(1,stm.Vis.CyclePicNumHf) 1*ones(1,stm.Vis.CyclePicNum) 2*ones(1,stm.Vis.CyclePicNumHf)];
            case 'SvF';	stm.Vis.TexSeq = [ 3*ones(1,stm.Vis.CyclePicNumHf) 1*ones(1,stm.Vis.CyclePicNum) 3*ones(1,stm.Vis.CyclePicNumHf)];
            case 'BvF';	stm.Vis.TexSeq = [ 4*ones(1,stm.Vis.CyclePicNumHf) 1*ones(1,stm.Vis.CyclePicNum) 4*ones(1,stm.Vis.CyclePicNumHf)];
            case 'OvF';	stm.Vis.TexSeq = [ 5*ones(1,stm.Vis.CyclePicNumHf) 1*ones(1,stm.Vis.CyclePicNum) 5*ones(1,stm.Vis.CyclePicNumHf)];
            case 'OvB';	stm.Vis.TexSeq = [ 5*ones(1,stm.Vis.CyclePicNumHf) 4*ones(1,stm.Vis.CyclePicNum) 5*ones(1,stm.Vis.CyclePicNumHf)];
            otherwise
        end
    end
    stm.Vis.TexSeq = [  stm.Vis.TexSeq; 
                        [1:stm.Vis.CyclePicNumHf    1:stm.Vis.CyclePicNum    1:stm.Vis.CyclePicNumHf]   ];

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
stm.Vis.Running =               1;     
    opts = struct(  'WindowStyle',  'non-modal',... 
                    'Interpreter',  'tex');
sys.MsgBox =	msgbox('\fontsize{20} Click to terminate the session after current visual cycle','', opts);

%% Play 
while stm.Vis.Running
    
    % Session timing
    stm.Vis.SesOn =           (   stm.Vis.CycleNumCurrent>0 && ...
                                    stm.Vis.CycleNumCurrent<=stm.Vis.CycleNumTotal);
    stm.Vis.CycleDurTotalCurrent =    toc(stm.Vis.CycleDurCurrentTimer); 
    
    %% Display 
    if stm.Vis.SesOn
        a = stm.Vis.TexIdxCurrent;
        stm.Vis.TexIdxCurrent =	...
            min(ceil(stm.Vis.CycleDurTotalCurrent/stm.Vis.PicDur), length(stm.Vis.TexSeq));
        if stm.Vis.TexIdxCurrent ~= a
            disp([sprintf('frame time:   '), datestr(now, 'HH:MM:SS.FFF')]);
            Screen('DrawTextures', stm.Vis.windowPtr,...
                stm.Vis.TexInd(...
                    stm.Vis.TexIdxAll(...
                        stm.Vis.CycleNumCurrent,...
                        stm.Vis.TexSeq(1, stm.Vis.TexIdxCurrent),...
                        stm.Vis.TexSeq(2, stm.Vis.TexIdxCurrent) ),...
                    stm.Vis.TexSeq(1, stm.Vis.TexIdxCurrent)        ),...
                [], (stm.Vis.MonitorCenter([1 2 1 2]) + stm.Vis.MonitorTexPatchPos)');
%             Screen('DrawingFinished', stm.Vis.windowPtr);                           % hold
            vbl = Screen('Flip', stm.Vis.windowPtr, vbl + 0.5*stm.Vis.TrialIFI);    % flip
        end
    end
	pause(0.01);
end

%% Clean up
pause(0.5);
        try sys.MsgBox.delete();    catch
        end
Screen('Close') 
close all;
save(['D:\=XINTRINSIC=\' stm.Vis.SesTime '_VisSeqData.mat'], 'stm', '-v7.3');
sca;
% dos('C:\Windows\System32\DisplaySwitch.exe /clone');