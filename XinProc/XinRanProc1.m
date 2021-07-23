function XinRanProc1(varargin)
% Xintrinsic preProcessing 1 
% DATA BINNNING

clear global
global A T R P
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
    A.RunningSource =   'D';
    [A.FileName, A.PathName, A.FilterIndex] = uigetfile(...
        [T.folder '*.rec'],...
        'Select raw recording files to process',...
        'MultiSelect',              'On');
    if A.FilterIndex == 0
        clear A;                    % nothing selected
        return
    end
    if iscell(A.FileName) == 0      % single file selected
        A.FileName = {A.FileName};
    end
else
    A.RunningSource =   'S';
    % Calling from another script
    [A.PathName, A.FileName, FileExt] = fileparts(varargin{1});
    A.PathName =        [A.PathName, '\'];
    A.FileName =        {[A.FileName, FileExt]};
end

disp(['Xintrinsic Processing Stage 1 (spatiotemporal binning) is about to start on ' ...
    num2str(length(A.FileName)) ' files']);

%% Parmateters
% R: Recorded
% P: Processed
% T: Temporal

R.SysCamPixelHeight =           300;
R.SysCamPixelWidth =            480;
R.SysCamPixelBinNum =           4;
R.SysCamFrameRate =             80;

% Bin 16 x 16 pixels together   (F)
P.ProcPixelBinNum =             2;
P.ProcPixelHeight =             R.SysCamPixelHeight/P.ProcPixelBinNum;
P.ProcPixelWidth =              R.SysCamPixelWidth/P.ProcPixelBinNum;

% Bin 16 frames together        (Proc)
P.ProcFrameRate =               5;
P.ProcFrameBinNum =             R.SysCamFrameRate/P.ProcFrameRate; 

T.hWaitbar =                    waitbar(0, 'processing');

%% DATA BINNING
for i = 1: length(A.FileName)
   
    %% Load 'S'
    T.filename = [A.PathName, A.FileName{i}];
    load([T.filename(1:end-3) 'mat']);  
    disp([  'Processing: "', A.FileName{i}, ...
            '" with the sound: "', S.SesSoundFile, '"']);
    
    %% Parameter initialization for Spatial & Temporal Binning  
    R.SesTrlNumTotal =          length(S.SesTrlOrderVec);
    R.SysCamFramePerTrial =     S.TrlDurTotal * R.SysCamFrameRate;
    P.ProcFramePerTrial =       S.TrlDurTotal * P.ProcFrameRate;   
    P.ProcFrameNumTotal =       S.SesFrameTotal / P.ProcFrameBinNum;
    
    T.fid =                     fopen(T.filename);
    
	P.RawMeanPixel =            zeros(1, S.SesFrameTotal);
    P.RawMeanPower =            zeros(1, S.SesFrameTotal);                                
    P.ProcMeanPixel =           zeros(1, P.ProcFrameNumTotal);
    P.ProcMeanPower =           zeros(1, P.ProcFrameNumTotal);
    
    P.ProcDataMat =             zeros(...
                                    S.SesCycleNumTotal,...
                                    S.TrlNumTotal,...
                                    P.ProcPixelHeight,...
                                    P.ProcPixelWidth,...
                                    P.ProcFramePerTrial...
                                    );   
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
            
            T.ImageS1 =         reshape(T.DataRaw,...  
                P.ProcPixelBinNum,     P.ProcPixelHeight, ...
                P.ProcPixelBinNum,     P.ProcPixelWidth, ...
                P.ProcFrameBinNum,     P.ProcFramePerTrial); 
            T.ImageS2 =         sum(T.ImageS1, 1);  
            T.ImageS3 =         sum(T.ImageS2, 3); 
            T.ImageS4 =         sum(T.ImageS3, 5);
            T.ImageS5 =         squeeze(T.ImageS4);
            P.ProcDataMat(j, T.TrialOrder, :, :, :) =...
                                        T.ImageS5;                         
        end    
    end
    % Power Processing
    if ~isempty(S.SesPowerMeter)
        P.RawMeanPower =    mean(S.SesPowerMeter, 2)';
        P.ProcMeanPower =   mean(reshape(P.RawMeanPower,...
                                    P.ProcFrameBinNum,...
                                    P.ProcFrameNumTotal), 1 );
    end
    %% Show Figure
    T.timeraw =                 (1:S.SesFrameTotal)/R.SysCamFrameRate;
    T.timebinned =              (1:P.ProcFrameNumTotal)/P.ProcFrameRate;
    figure(     'Name',         A.FileName{i});
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
        sprintf('_%dx%d@%dfps', P.ProcPixelHeight, P.ProcPixelWidth, P.ProcFrameRate),...
        '_P1.mat'], 'P', '-v7.3');     
    fclose(T.fid);
end

close(T.hWaitbar);
disp('All files are processed');
clear T P R
return;
