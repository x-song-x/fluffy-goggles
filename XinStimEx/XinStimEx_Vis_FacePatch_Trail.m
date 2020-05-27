function XinStimEx_Vis_FacePatch_Trail

%% Switch multi-display mode
clear all
Screen('Close') 
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
clear stm sys;              % Clear the workspace
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
stm.SesDurTotal =       320;                                
% stm.Vis.PicSource = '\Wang\phase_stimuli';
% stm.Vis.PicSource = '\Hung\phase_stimuli';
% stm.Vis.PicSource = '\P002\equalized';
% stm.Vis.PicSource = '\P002\pink2_fullscreen';
% stm.Vis.PicSource = '\P002\pink_song_pattern';
% stm.Vis.PicSource = '\P002\pink_song_shifthalf';
stm.Vis.PicSource = '\Last\shifthalf';

% stm.Vis.PicBackground = 'white';
stm.Vis.PicBackground =     'pink';
stm.Vis.PicDur =            0.5;
stm.Vis.PicNumStim =        20;
stm.Vis.SesOptionContrast = 'FBAVOUPS';
    % 'F';  Faces
    % 'B';  Body parts
    % 'A';  Animals               
    % 'V';  Fruits & Vegetables	
    % 'O';  Familiar Objects 
    % 'U';  Unfamiliar Objects 
    % 'P';  Phase scrambled Faces
    % 'S';  Spatially scrambled Faces
stm.Vis.TrlDurTotal =       20;
stm.Vis.TrlDurPreStim =     2;
stm.Vis.TrlDurStim =        stm.Vis.PicDur*stm.Vis.PicNumStim;
stm.Vis.TrlDurPostStim =    stm.Vis.TrlDurTotal - stm.Vis.TrlDurPreStim - stm.Vis.TrlDurStim;
stm.Vis.TrlNumTotal =       length(stm.Vis.SesOptionContrast);
stm.Vis.TrlNames =          cellstr(stm.Vis.SesOptionContrast');     
stm.Vis.TrlIndexSoundNum =  1:stm.Vis.TrlNumTotal;
stm.Vis.TrlIndexAddAttNum = ones(1, stm.Vis.TrlNumTotal);

%% Visual CO Parameters
% Session Timer 
stm.Vis.SesCycleDurTotal =      stm.Vis.TrlDurTotal *stm.Vis.TrlNumTotal;           % in second
stm.Vis.SesCycleNumTotal =      floor(stm.SesDurTotal/stm.Vis.SesCycleDurTotal);	% rep # total
stm.Vis.SesDurTotal =           stm.Vis.SesCycleNumTotal*stm.Vis.SesCycleDurTotal;  % in second
stm.Vis.SesSoundDurTotal =      stm.Vis.SesCycleDurTotal;
stm.Vis.AddAtts =               0;
stm.Vis.AddAttNumTotal =        1;

stm.Vis.SesTrlOrder =           'Randomized';
stm.Vis.SesTrlOrderMat =        [];
    for i = 1:stm.Vis.SesCycleNumTotal
        stm.Vis.SesTrlOrderMat= [stm.Vis.SesTrlOrderMat; randperm(stm.Vis.TrlNumTotal)];
    end    
   
        stm.Vis.SesTrlOrderVec= reshape(stm.Vis.SesTrlOrderMat',1,[]);
        stm.Vis.SesTrlOrderSoundVec = stm.Vis.TrlIndexSoundNum(stm.Vis.SesTrlOrderVec);             

stm.Vis.CtrlTrlNumTotal =       stm.Vis.SesCycleNumTotal*stm.Vis.TrlNumTotal;  % in second
stm.Vis.CtrlTrlNumCurrent =     0;
stm.Vis.CtrlTrlDurCurrentTimer=	tic;
stm.Vis.PicNumPreStim =         round(stm.Vis.TrlDurPreStim/    stm.Vis.PicDur);
stm.Vis.PicNumPostStim =        round(stm.Vis.TrlDurPostStim/   stm.Vis.PicDur);

% Display Device
stm.Vis.MonitorName =       'LG 32GK850F-B';
stm.Vis.MonitorDistance =   75;             % in cm
stm.Vis.MonitorHeight =     0.02724*1440;	% in cm
stm.Vis.MonitorWidth =      0.02724*2560;	% in cm

%% Prepare the Psychtoolbox window
% Here we call some default settings for setting up Psychtoolbox
                                                PsychDefaultSetup(2);
% Define shades
gray =  GrayIndex(sys.screenNumber, 0.5);   
                                                Screen('Preference', 'VisualDebugLevel', 1);
                                                Screen('Preference', 'SkipSyncTests', 1);
% Open an on screen window
switch stm.Vis.PicBackground
    case 'gray';    [stm.Vis.windowPtr, ~] = PsychImaging('OpenWindow', sys.screenNumber, gray);
    case 'pink';    [stm.Vis.windowPtr, ~] = PsychImaging('OpenWindow', sys.screenNumber, gray);
        % display a pink noise background
        stm.Vis.Tex0 =      pinknoiseimage(1440, 2560);
        stm.Vis.Tex0Ind =   Screen('MakeTexture',   stm.Vis.windowPtr,	stm.Vis.Tex0);
                            Screen('DrawTextures',  stm.Vis.windowPtr,  stm.Vis.Tex0Ind);
        vbl =               Screen('Flip',          stm.Vis.windowPtr);
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
% vbl = Screen('Flip', stm.Vis.windowPtr);

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
for i = 1:stm.Vis.TrlNumTotal
    switch stm.Vis.TrlNames{i}
        case 'F';   stm.Vis.TexImFileFormat{i} = 'SHINEd_m%d.tif';
        case 'A';   stm.Vis.TexImFileFormat{i} = 'SHINEd_a%d.tif';
        case 'V';   stm.Vis.TexImFileFormat{i} = 'SHINEd_f%d.tif';
        case 'O';   stm.Vis.TexImFileFormat{i} = 'SHINEd_o%d.tif';
        case 'U';   stm.Vis.TexImFileFormat{i} = 'SHINEd_u%d.tif';
        case 'B';   stm.Vis.TexImFileFormat{i} = 'SHINEd_b%d.tif';
        case 'P';   stm.Vis.TexImFileFormat{i} = 'SHINEd_p%d.tif';
        case 'S';   stm.Vis.TexImFileFormat{i} = 'SHINEd_s%d.tif';
        otherwise
    end
	for j = 1:20
        stm.Vis.TexIm{i,j} =	imread([stm.Vis.TexImDir sprintf(stm.Vis.TexImFileFormat{i}, j)]);
        stm.Vis.TexInd(i,j) =	Screen('MakeTexture', stm.Vis.windowPtr, stm.Vis.TexIm{i,j}); 
	end
end
    for j = 1:20        
        stm.Vis.PbgIm{j} =      pinknoiseimage(1440, 2560);
        stm.Vis.PbgInd(j) =     Screen('MakeTexture', stm.Vis.windowPtr, stm.Vis.PbgIm{j}); 
    end
        
% pre-arrange image sequence
stm.Vis.TexIdxCurrent =     0;  
stm.Vis.TexIdxAll =         [];
for i = 1:stm.Vis.CtrlTrlNumTotal
	stm.Vis.TexIdxAll(i, :) =    randperm(20);
end
    stm.Vis.TexIdxAll =     [   stm.Vis.TexIdxAll(:, 1:stm.Vis.PicNumPreStim),...
                                stm.Vis.TexIdxAll(:, 1:stm.Vis.PicNumStim),...
                                stm.Vis.TexIdxAll(:, stm.Vis.PicNumPreStim+(1:stm.Vis.PicNumPostStim) ) ];
	stm.Vis.TexIdxType =    [   1*ones(1,   stm.Vis.PicNumPreStim),...
                                2*ones(1,   stm.Vis.PicNumStim),...
                                3*ones(1,   stm.Vis.PicNumPostStim)     ];

%% NI-DAQ
sys.NIDAQ.D.InTimebaseRate =    stm.SR;
sys.NIDAQ.D.TrialSmplHigh =     2;
sys.NIDAQ.D.TrialSmplLow =      sys.NIDAQ.D.InTimebaseRate * stm.Vis.TrlDurTotal - ...
                                sys.NIDAQ.D.TrialSmplHigh;
import dabs.ni.daqmx.*
sys.NIDAQ.TaskCO = Task('Recording Session Cycle Switcher3');
sys.NIDAQ.TaskCO.createCOPulseChanTicks(...
    'Dev3', 1, 'Cycle Counter', '100kHzTimebase', ...
    sys.NIDAQ.D.TrialSmplLow, sys.NIDAQ.D.TrialSmplHigh,...
    0, 'DAQmx_Val_Low');
sys.NIDAQ.TaskCO.cfgImplicitTiming(...
    'DAQmx_Val_FiniteSamps',	stm.Vis.CtrlTrlNumTotal+1);
sys.NIDAQ.TaskCO.cfgDigEdgeStartTrig(...
    'RTSI6',            'DAQmx_Val_Rising');
sys.NIDAQ.TaskCO.registerSignalEvent(...
    @XinStimEx_Vis_FacePatch_Trial_Callback, 'DAQmx_Val_CounterOutputEvent');
sys.NIDAQ.TaskCO.start()
stm.Vis.Running =               1;     
    opts = struct(  'WindowStyle',  'non-modal',... 
                    'Interpreter',  'tex');
sys.MsgBox =	msgbox('\fontsize{20} Click to terminate the session after current visual cycle','', opts);

%% Play 
while stm.Vis.Running
    
    % Session timing
    stm.Vis.SesOn =           (   stm.Vis.CtrlTrlNumCurrent>0 && ...
                                    stm.Vis.CtrlTrlNumCurrent<=stm.Vis.CtrlTrlNumTotal);
    stm.Vis.CtrlTrlDurCurrent =    toc(stm.Vis.CtrlTrlDurCurrentTimer); 
    
    %% Display 
    if stm.Vis.SesOn
        a = stm.Vis.TexIdxCurrent;
        stm.Vis.TexIdxCurrent =	...
            min(ceil(stm.Vis.CtrlTrlDurCurrent/stm.Vis.PicDur),	stm.Vis.PicNumPreStim + ...
                                                                stm.Vis.PicNumStim + ...
                                                                stm.Vis.PicNumPostStim);
        if stm.Vis.TexIdxCurrent ~= a
            disp([sprintf('frame time:   '), datestr(now, 'HH:MM:SS.FFF')]);
            switch stm.Vis.TexIdxType(stm.Vis.TexIdxCurrent)
                case 1; stm.Vis.TexIdxNow = stm.Vis.PbgInd( stm.Vis.TexIdxAll(stm.Vis.CtrlTrlNumCurrent, stm.Vis.TexIdxCurrent));
                case 2; stm.Vis.TexIdxNow = stm.Vis.TexInd( stm.Vis.SesTrlOrderVec(stm.Vis.CtrlTrlNumCurrent),...
                                                            stm.Vis.TexIdxAll(stm.Vis.CtrlTrlNumCurrent, stm.Vis.TexIdxCurrent));
                case 3; stm.Vis.TexIdxNow = stm.Vis.PbgInd( stm.Vis.TexIdxAll(stm.Vis.CtrlTrlNumCurrent, stm.Vis.TexIdxCurrent)); 
                otherwise
            end                    
            Screen('DrawTextures', stm.Vis.windowPtr,stm.Vis.TexIdxNow,...
                [], (stm.Vis.MonitorCenter([1 2 1 2]) + stm.Vis.MonitorTexPatchPos)');
%             Screen('DrawingFinished', stm.Vis.windowPtr);                           % hold
            vbl = Screen('Flip', stm.Vis.windowPtr, vbl + 0.5*stm.Vis.TrialIFI);    % flip
        end
    end
	pause(0.01);
end

%% Clean up
pause(2.0);
        try sys.MsgBox.delete();    catch
        end
Screen('Close') 
close all;
save(['D:\=XINTRINSIC=\' stm.Vis.SesTime '_VisSeqData.mat'], 'stm', '-v7.3');
sca;
% dos('C:\Windows\System32\DisplaySwitch.exe /clone');

function image = pinknoiseimage(a,b)
% pn.a = 1440;
% pn.b = 2560;
pn.level = 115;
pn.a = a;
pn.b = b;
pn.beta = 1;
pn.fha = pn.a/2+1;
pn.fhb = pn.b/2+1;
pn.fhimagea = (0:pn.a/2)'*ones(1, pn.fhb);
pn.fhimageb = ones(pn.fha,1)*(0:pn.b/2);
pn.fhimagef = ((pn.fhimagea.^2 + pn.fhimageb.^2).^(1/2));
pn.fhimagefbeta = pn.fhimagef.^(-pn.beta);
pn.fhimagefbeta(1,1) = 0;
pn.fhimageagl1 = rand(pn.fha, pn.fhb)*2*pi;
pn.fhimageagl2 = rand(pn.fha, pn.fhb)*2*pi;
pn.fhimageagl1(end,1) = 0;
pn.fhimageagl1(1, end) = 0;
pn.fhimageagl1(end, end) = 0;
pn.fhimagecomp1 = complex(pn.fhimagefbeta.*cos(pn.fhimageagl1), pn.fhimagefbeta.*sin(pn.fhimageagl1));
pn.fhimagecomp2 = complex(pn.fhimagefbeta.*cos(pn.fhimageagl2), pn.fhimagefbeta.*sin(pn.fhimageagl2));
pn.fimagecomp = [...
pn.fhimagecomp1 fliplr([conj(pn.fhimagecomp1(1,2:end-1)); pn.fhimagecomp2(2:end-1,2:end-1); conj(pn.fhimagecomp1(end,2:end-1))])];
pn.fimagecomp = [pn.fimagecomp;...
conj(flipud([pn.fhimagecomp1(2:end-1,1), fliplr(pn.fimagecomp(2:end-1,2:end))]))];
pn.image = ifft2(pn.fimagecomp);
pn.imagemax = max(max(pn.image));
pn.imagemin = min(min(pn.image));
% image = uint8((pn.image-pn.imagemin)/(pn.imagemax-pn.imagemin)*255);
pn.imagemaxn = abs(pn.imagemax/(255-pn.level));
pn.imageminn = abs(pn.imagemin/(pn.level-0));
pn.imageampn = max(pn.imagemaxn, pn.imageminn);
image = uint8(pn.image/pn.imageampn+pn.level);
