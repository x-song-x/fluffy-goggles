function XinRanProc2(varargin)
% Xintrinsic preProcessing 1 
% DATA BINNNING

clear global
global T R P
%% Get preprocessed ('*.rec') file
[~, T.pcname] = system('hostname');
if strcmp(T.pcname(1:end-1), 'FANTASIA-425')
    % if current computer is the recording computer 
        T.folder = 'D:\=XINTRINSIC=\';    
else
    % if current computer is NOT a recording computer
        T.folder = 'X:\';       
end

if nargin ==0
    % Calling from direct running of the function
    T.RunningSource =   'D';
    [T.FileName, T.PathName, T.FilterIndex] = uigetfile(...
        [T.folder '*.rec'],...
        'Select raw recording files to process',...
        'MultiSelect',              'On');
    if T.FilterIndex == 0
        clear A;                    % nothing selected
        return
    end
    if iscell(T.FileName) == 0      % single file selected
        T.FileName = {T.FileName};
    end
else
    T.RunningSource =   'S';
    % Calling from another script
    [T.PathName, T.FileName, FileExt] = fileparts(varargin{1});
    T.PathName =        [T.PathName, '\'];
    T.FileName =        {[T.FileName, FileExt]};
end

disp(['Xintrinsic Processing Stage 1 (spatiotemporal binning) is about to start on ' ...
    num2str(length(T.FileName)) ' files']);

%% Parmateters
% R: Recorded
% P: Processed
% T: Temporal
P.ProcFrameRate =       5;
% P.ProcFrameRate =       20;
% P.ProcPixelBinNum =     4;
P.ProcPixelBinNum =     3;

P.RecCanvasHeight =     300;
P.RecCanvasWidth =      480;
P.ProcPixelHeight =     P.RecCanvasHeight/P.ProcPixelBinNum;
P.ProcPixelWidth =      P.RecCanvasWidth /P.ProcPixelBinNum;
T.hWaitbar =                    waitbar(0, 'processing');

%% DATA BINNING
for i = 1: length(T.FileName)
   
    %% Load 'S'
    T.filename = [T.PathName, T.FileName{i}];
    load([T.filename(1:end-3) 'mat']);  
    disp([  'Processing: "', T.FileName{i}, ...
            '" with the sound: "', S.SesSoundFile, '"']);
	% Default Paremeters (for files older than 2020/11/27)
	switch [S.SysCamMain '_' S.SysCamDeviceName]
       case 'PointGrey_Grasshopper3 GS3-U3-23S6M'
            R.SysCamPixelHeight =	300;
            R.SysCamPixelWidth =	480;
            R.SysCamFrameRate =     80;
       case 'Thorlabs_CS2100M-USB'
            R.SysCamPixelHeight =	270;
            R.SysCamPixelWidth =	480;
            R.SysCamFrameRate =     20;
       otherwise
           disp('unrecognizable camera')
	end
            R.SysCamBinNumber =     4;
            R.SesTrlNumTotal =      length(S.SesTrlOrderVec);
            R.SysCamFramePerTrial =	S.TrlDurTotal * R.SysCamFrameRate;
    % Other Paremeters (for files after 2020/11/27)
    if isfield(S, 'SysCamFrameRate')
            R.SysCamFrameRate =     S.SysCamFrameRate;
            R.SysCamBinNumber =     S.SysCamBinNumber;
            R.SysCamPixelHeight =   S.SysCamResolution(1)/S.SysCamBinNumber;
            R.SysCamPixelWidth =    S.SysCamResolution(2)/S.SysCamBinNumber;
    end
    %% Proc Parameters
    %% Poc Parameter initialization for Spatial & Temporal Binning  
    P.ProcCamPixelHeight =	R.SysCamPixelHeight/P.ProcPixelBinNum;
    P.ProcCamPixelWidth =	R.SysCamPixelWidth /P.ProcPixelBinNum;
    P.ProcFrameBinNum = R.SysCamFrameRate/P.ProcFrameRate; 
    
    P.ProcFramePerTrial =       S.TrlDurTotal * P.ProcFrameRate;   
    P.ProcFrameNumTotal =       S.SesFrameTotal / P.ProcFrameBinNum;
    
    T.fid =                     fopen(T.filename);
	P.RawMeanPixel =            zeros(1, S.SesFrameTotal);
    P.RawMeanPower =            zeros(1, S.SesFrameTotal);                                
    P.ProcMeanPixel =           zeros(1, P.ProcFrameNumTotal);
    P.ProcMeanPower =           zeros(1, P.ProcFrameNumTotal);    
    P.ProcDataMat =             ones(...    
                                    S.SesCycleNumTotal,...
                                    S.TrlNumTotal,...
                                    P.ProcPixelHeight,...
                                    P.ProcPixelWidth,...
                                    P.ProcFramePerTrial...
                                    );   
        % leave some 0s at the edge would mess up normalization later
	P.ProcDataMatHeightIndex =  (1:P.ProcCamPixelHeight) + ...
                                round((P.ProcPixelHeight-P.ProcCamPixelHeight)/2);
	P.ProcDataMatWidthIndex =   (1:P.ProcCamPixelWidth) + ...
                                round((P.ProcPixelWidth -P.ProcCamPixelWidth )/2);
%     P.ProcDataMat =             zeros(...
%                                     S.SesCycleNumTotal,...
%                                     S.TrlNumTotal,...
%                                     P.ProcCamPixelHeight,...
%                                     P.ProcCamPixelWidth,...
%                                     P.ProcFramePerTrial...
%                                     );   
    for j = 1:S.SesCycleNumTotal
        for k = 1:S.TrlNumTotal
            m = (j-1)*S.TrlNumTotal + k;
            %% Update GUI
            waitbar(m/R.SesTrlNumTotal, T.hWaitbar,...
                ['finishing ',...
                sprintf('%d out of %d total trials in the session',...
                    m, R.SesTrlNumTotal)] );       
            %% Read Data Batch  
            T.DataRaw = 	fread(T.fid, [...
                R.SysCamPixelHeight * R.SysCamPixelWidth, ...
                R.SysCamFramePerTrial],...
                'uint16');
            %% Frame #, Trial order # location        
            T.RecFramesCurrent =    ((m-1)*	R.SysCamFramePerTrial +1):...
                                    (m*     R.SysCamFramePerTrial);
            T.ProcFramesCurrent =   ((m-1)*	P.ProcFramePerTrial +1):...
                                    (m*     P.ProcFramePerTrial);        
            T.TrialOrder =          S.SesTrlOrderVec(m);            
            %% Image Processing
            T.PixelMeanRaw =        mean(T.DataRaw, 1);
            T.PixelMeanBinned =     mean( reshape(...
                                                T.PixelMeanRaw,...
                                                P.ProcFrameBinNum,...
                                                P.ProcFramePerTrial), 1 );
            P.RawMeanPixel(T.RecFramesCurrent) =    T.PixelMeanRaw;
            P.ProcMeanPixel(T.ProcFramesCurrent) =  T.PixelMeanBinned;  
            
            switch [S.SysCamMain '_' S.SysCamDeviceName]
               case 'PointGrey_Grasshopper3 GS3-U3-23S6M'
                    T.ImageS0 =         reshape(T.DataRaw,...  
                        P.ProcPixelBinNum,     P.ProcCamPixelHeight, ...
                        P.ProcPixelBinNum,     P.ProcCamPixelWidth, ...
                        P.ProcFrameBinNum,     P.ProcFramePerTrial);
                    T.ImageS1 =         T.ImageS0;
                case 'Thorlabs_CS2100M-USB'
                    T.ImageS0 =         reshape(T.DataRaw,...  
                        P.ProcPixelBinNum,     P.ProcCamPixelWidth, ...
                        P.ProcPixelBinNum,     P.ProcCamPixelHeight, ...
                        P.ProcFrameBinNum,     P.ProcFramePerTrial);
                    T.ImageS1 =         permute(T.ImageS0, [3 4 1 2 5 6]); 
            end 
            T.ImageS2 =         sum(T.ImageS1, 1);  
            T.ImageS3 =         sum(T.ImageS2, 3); 
            T.ImageS4 =         sum(T.ImageS3, 5);
            T.ImageS5 =         squeeze(T.ImageS4);
            P.ProcDataMat(j, T.TrialOrder, P.ProcDataMatHeightIndex, P.ProcDataMatWidthIndex, :) =...
                                        T.ImageS5;                         
        end    
    end
        %% Power Processing
%         P.RawMeanPower =    mean(S.SesPowerMeter, 2)';
%         P.ProcMeanPower =   mean(reshape(P.RawMeanPower,...
%                                     P.ProcFrameBinNum,...
%                                     P.ProcFrameNumTotal), 1 );
    %% Show Figure
    T.timeraw =                 (1:S.SesFrameTotal)/R.SysCamFrameRate;
    T.timebinned =              (1:P.ProcFrameNumTotal)/P.ProcFrameRate;
    figure(     'Name',         T.FileName{i});
    subplot(2,1,1);
    [T.hAx,~,~] =       plotyy(	T.timeraw,      P.RawMeanPower, ...
                                T.timeraw,      P.RawMeanPixel);
    xlabel(T.hAx(1),        'Time (sec)');
    ylabel(T.hAx(1),        'Power Mean (volt)');
    ylabel(T.hAx(2),        'Pixel Mean (ADU)');
    subplot(2,1,2);
    [T.hAx, T.hP1, T.hP2] = ...
                        plotyy(	T.timebinned,   P.ProcMeanPower, ...
                                T.timebinned,   P.ProcMeanPixel);    
%     T.hP2.LineWidth =       2;                     
    xlabel(T.hAx(1),        'Time (sec)');
    ylabel(T.hAx(1),        'Power Mean (volt)');
    ylabel(T.hAx(2),        'Pixel Mean (ADU)');
    
    save([T.filename(1:end-4),...
        sprintf('_%dx%d@%dfps', P.ProcCamPixelHeight, P.ProcCamPixelWidth, P.ProcFrameRate),...
        '_P1.mat'], 'P', '-v7.3');     
    fclose(T.fid);
end

close(T.hWaitbar);
disp('All files are processed');
clear T P R
return;
