function XinRanProc1_FaceTrial(varargin)
% Xintrinsic preProcessing 1 
% DATA BINNNING

clear global
global A P S stm
%% Get preprocessed ('*.rec') file
[~, A.Sys.pcname] = system('hostname');
if strcmp(A.Sys.pcname(1:end-1), 'FANTASIA-425')
    % if current computer is the recording computer 
        A.Sys.folder = 'D:\=XINTRINSIC=\';    
else
    % if current computer is NOT a recording computer
        A.Sys.folder = 'X:\';       
end

if nargin ==0
    % Calling from direct running of the function
    A.RunningSource =   'D';
    [A.FileName, A.PathName, A.FilterIndex] = uigetfile(...
        [A.Sys.folder '*.rec'],...
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

A.sysCamPixelHeight =           300;
A.sysCamPixelWidth =            480;
A.sysCamPixelBinNum =           4;
A.sysCamFrameRate =             80;

% Bin 16 x 16 pixels together   (F)
P.ProcPixelBinNum =             1;
P.ProcPixelHeight =             A.sysCamPixelHeight/P.ProcPixelBinNum;
P.ProcPixelWidth =              A.sysCamPixelWidth/P.ProcPixelBinNum;

% Bin 16 frames together        (Proc)
P.ProcFrameRate =               5;
P.ProcFrameBinNum =             A.sysCamFrameRate/P.ProcFrameRate; 

A.Sys.hWaitbar =                    waitbar(0, 'processing');

%% Get the Visual Stim infomation in *VisSeqData.mat'
A.FileList = dir(A.PathName);
A.FolderFileList = dir(A.PathName);
A.VisSeqDataList = struct('name',[], 'folder',[], 'date', [], 'bytes', [], 'isdir', [], 'datenum', []);
A.VisSeqDataDatenum = [];
A.VisSeqDataNumTotal = 0;
for i = 1:length(A.FolderFileList)
    if length(A.FileList(i).name)>15
        if strcmp(A.FileList(i).name(end-13:end), 'VisSeqData.mat')
        	A.VisSeqDataNumTotal = A.VisSeqDataNumTotal +1;
            A.VisSeqDataList(A.VisSeqDataNumTotal,1) = A.FileList(i);
            A.VisSeqDataDatenum(A.VisSeqDataNumTotal,1) = ...
                datenum(A.VisSeqDataList(A.VisSeqDataNumTotal,1).name(1:15), 'yyyymmddTHHMMSS');
        end
    end
end
for i = 1: length(A.FileName)
    A.FileDatenum(i) = datenum(A.FileName{i}(1:13), 'yymmddTHHMMSS');
    aa = 24*60*60*(A.VisSeqDataDatenum - A.FileDatenum(i));
    A.FileNum4VisSeqData(i,1) = find(aa>0, 1);
	A.FileLag4VisSeqData(i,1) = min(aa(aa>0));
end            
figure;
plot(A.FileLag4VisSeqData);
drawnow;
% return

%% DATA BINNING
for i = 1: length(A.FileName)
   
    %% Load 'S'
    A.curfilename = [A.PathName, A.FileName{i}];
    S = load([A.curfilename(1:end-3) 'mat']);  
    S = S.S;
    disp([  'Processing: "', A.FileName{i}, ...
            '" with the sound: "', S.SesSoundFile, '"']);
    %% Load 'stm'
    stm = load([  A.VisSeqDataList(A.FileNum4VisSeqData(i)).folder, '\',...
            A.VisSeqDataList(A.FileNum4VisSeqData(i)).name]);
    stm = stm.stm;
    %% Replace compoents in 'S' with 'stm'
    if stm.Vis.SesDurTotal == S.SesDurTotal
        S.TrlDurTotal =     stm.Vis.TrlDurTotal;
        S.TrlDurPreStim =   stm.Vis.TrlDurPreStim;
        S.TrlDurStim =      stm.Vis.TrlDurStim;
        S.TrlDurPostStim =	stm.Vis.TrlDurPostStim;
        S.TrlNumTotal =     stm.Vis.TrlNumTotal;
        S.TrlNames =        stm.Vis.TrlNames;
        S.TrlIndexSoundNum=	stm.Vis.TrlIndexSoundNum;
        S.TrlIndexAddAttNum=stm.Vis.TrlIndexAddAttNum;
        S.SesCycleDurTotal=	stm.Vis.SesCycleDurTotal;
        S.SesCycleNumTotal=	stm.Vis.SesCycleNumTotal;
        S.SesDurTotal =     stm.Vis.SesDurTotal;        
        S.SesSoundDurTotal= stm.Vis.SesSoundDurTotal;
        S.AddAtts =         stm.Vis.AddAtts;
        S.AddAttNumTotal =  stm.Vis.AddAttNumTotal;
        S.SesTrlOrder =     stm.Vis.SesTrlOrder;
        S.SesTrlOrderMat =  stm.Vis.SesTrlOrderMat;
        S.SesTrlOrderVec =  stm.Vis.SesTrlOrderVec;
        S.SesTrlOrderSoundVec = stm.Vis.SesTrlOrderSoundVec;
    else
        disp('stm and S matching error');
        return
    end
    save([A.curfilename(1:end-4), '_VisSeq.mat'], 'S', '-v7.3');   
    
    %% Parameter initialization for Spatial & Temporal Binning  
    A.SesTrlNumTotal =          length(S.SesTrlOrderVec);
    A.sysCamFramePerTrial =     S.TrlDurTotal * A.sysCamFrameRate;
    P.ProcFramePerTrial =       S.TrlDurTotal * P.ProcFrameRate;   
    P.ProcFrameNumTotal =       S.SesFrameTotal / P.ProcFrameBinNum;
    
    A.curfid =                  fopen(A.curfilename);
    
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
            waitbar(m/A.SesTrlNumTotal, A.Sys.hWaitbar,...
                ['finishing ',...
                sprintf('%d out of %d total trials in the session',...
                    m, A.SesTrlNumTotal)] );       
            %% Read Data Batch    
            A.DataRaw = 	fread(A.curfid, [...
                A.sysCamPixelHeight * A.sysCamPixelWidth, ...
                A.sysCamFramePerTrial],...
                'uint16');
            %% Frame #, Trial order # location        
            A.RecFramesCurrent =    ((m-1)*	A.sysCamFramePerTrial +1):...
                                    (m*     A.sysCamFramePerTrial);
            A.ProcFramesCurrent =   ((m-1)*	P.ProcFramePerTrial +1):...
                                    (m*     P.ProcFramePerTrial);        
            A.TrialOrder =          S.SesTrlOrderVec(m);            
            %% Image Processing
            A.PixelMeanRaw =        mean(A.DataRaw, 1);
            A.PixelMeanBinned =     mean( reshape(...
                                                A.PixelMeanRaw,...
                                                P.ProcFrameBinNum,...
                                                P.ProcFramePerTrial), 1 );
            P.RawMeanPixel(A.RecFramesCurrent) =    A.PixelMeanRaw;
            P.ProcMeanPixel(A.ProcFramesCurrent) =  A.PixelMeanBinned;  
            
            A.ImageS1 =         reshape(A.DataRaw,...  
                P.ProcPixelBinNum,     P.ProcPixelHeight, ...
                P.ProcPixelBinNum,     P.ProcPixelWidth, ...
                P.ProcFrameBinNum,     P.ProcFramePerTrial); 
            A.ImageS2 =         sum(A.ImageS1, 1);  
            A.ImageS3 =         sum(A.ImageS2, 3); 
            A.ImageS4 =         sum(A.ImageS3, 5);
            A.ImageS5 =         squeeze(A.ImageS4);
            P.ProcDataMat(j, A.TrialOrder, :, :, :) =...
                                        A.ImageS5;                         
        end    
    end
    %% Show Figure
    A.timeraw =                 (1:S.SesFrameTotal)/A.sysCamFrameRate;
    A.timebinned =              (1:P.ProcFrameNumTotal)/P.ProcFrameRate;
    figure(     'Name',         A.FileName{i});
    subplot(2,1,1);
    [A.hAx,~,~] =       plotyy(	A.timeraw,      P.RawMeanPower, ...
                                A.timeraw,      P.RawMeanPixel);
    xlabel(A.hAx(1),        'Time (sec)');
    ylabel(A.hAx(1),        'Power Mean (volt)');
    ylabel(A.hAx(2),        'Pixel Mean (ADU)');
    subplot(2,1,2);
    [A.hAx, A.hP1, A.hP2] = ...
                        plotyy(	A.timebinned,   P.ProcMeanPower, ...
                                A.timebinned,   P.ProcMeanPixel);    
%     A.hP2.LineWidth =       2;                     
    xlabel(A.hAx(1),        'Time (sec)');
    ylabel(A.hAx(1),        'Power Mean (volt)');
    ylabel(A.hAx(2),        'Pixel Mean (ADU)');
    
    save([A.curfilename(1:end-4),...
        sprintf('_%dx%d@%dfps', P.ProcPixelHeight, P.ProcPixelWidth, P.ProcFrameRate),...
        '_VisSeq_P1.mat'], 'P', '-v7.3');     
    fclose(A.curfid);
end

close(A.Sys.hWaitbar);
disp('All files are processed');
return;
