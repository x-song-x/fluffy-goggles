function XinRanProc21(varargin)
% Xintrinsic preProcessingDATA BINNNING

global S P Tm Sys
% P:    Processed, To be saved
% Tm: 	Temporary
% Sys:  System parameters, if not in "S" yet
P = [];     Tm =[];     Sys = []; 
  
%% Get preprocessed ('*.rec') file(s)
[~, Tm.pcname] = system('hostname');
if strcmp(Tm.pcname(1:end-1), 'FANTASIA-425')	% recording computer 
        Tm.folder = 'D:\=XINTRINSIC=\';    
else                                        % NOT recording computer
        Tm.folder = 'X:\';       
end
if nargin ==0           % Calling from direct running of the function
    Tm.RunningSource =   'D';
    [Tm.FileName, Tm.PathName, Tm.FilterIndex] = uigetfile(...
        [Tm.folder '*.rec'], 'Select raw recording files to process',...
        'MultiSelect',              'On');
    if Tm.FilterIndex == 0            
        return;                         % nothing selected
    end
    if iscell(Tm.FileName) == 0          % single file selected
        Tm.FileName = {Tm.FileName};
    end
    Sys.ProcFrameRate =     5;
    Sys.ProcPixelBinNum =	4;
else                    % Calling from another script
    Tm.RunningSource =   'S';
    [Tm.PathName, Tm.FileName, FileExt] = fileparts(varargin{1});
    Tm.PathName =        [Tm.PathName, '\'];
    Tm.FileName =        {[Tm.FileName, FileExt]};
    Sys.ProcFrameRate =     varargin{2};
    Sys.ProcPixelBinNum =	varargin{3};
end
    % 3 things specified here:
    % (1) files to be pre-processed
    % (2) ProcFrameRate,    usually downsampled from 80 or 20 fps to 5 fps
    % (3) ProcPixelBinNum,  usually 4 for FLIR, 3 for Thorlabs
disp(['Xintrinsic Processing Stage 1 (spatiotemporal binning) is about to start on ' ...
    num2str(length(Tm.FileName)) ' files']);

%% DATA Preprocessing for each file (Binning)
Tm.hWaitbar =	waitbar(0, 'processing');
Tm.SFields = {...
    'SysCamMain',       'SysCamDeviceName', 'SysCamFrameRate',...
    'SysCamBinNumber',  'SysCamResolution', ...
    'SesSoundFile',     'SesTrlOrderVec',   'SesCycleNumTotal',...
    'SesFrameTotal',    'SesFrameNum', ...
    'TrlNumTotal',      'TrlDurTotal',  'TrlDurPreStim', 'TrlDurStim'};
for i = 1: length(Tm.FileName)
    % Load 'S'
        Tm.filename = [Tm.PathName, Tm.FileName{i}];
        if ~isfile([Tm.filename(1:end-3) 'mat'])
            disp(['Skipping aborted file:' Tm.FileName{i}]);
            continue;
        end
        Tm.SFieldList = whos('-file', [Tm.filename(1:end-3) 'mat']);
        if strcmp(Tm.SFieldList(1).name, 'S')   % 'S' struct saved in .mat (pre 220727)
            S =  load([Tm.filename(1:end-3) 'mat']);
            S =  S.S;
        else                                    % 'S' fields saved in .mat (post 220727)
            S = [];
            for j = 1:length(Tm.SFields)
                Tm.ST = load([Tm.filename(1:end-3) 'mat'], Tm.SFields{j});
                S.(Tm.SFields{j}) = Tm.ST.(Tm.SFields{j});
            end
        end
        disp([  'Processing: "', Tm.FileName{i}, ...
                '" with the sound: "', S.SesSoundFile, '"']);
	% Default Paremeters (for files older than 2020/11/27)
                        Sys.SysIdentifier = 'PointGrey_Grasshopper3 GS3-U3-23S6M';
                        Sys.SysCamFrameRate =	    80;
                        Sys.SysCamBinNumber =	    4;
                        Sys.SysCamPixelHeight =	    300;
                        Sys.SysCamPixelWidth =	    480;
                        Sys.SysCamFrameHeight1st =  1;
    % Update further parameters if specified in 'S'
        if isfield(S, 'SysCamFrameRate')    % overwrite if available (for files after 201127) 
                        Sys.SysCamFrameRate =       S.SysCamFrameRate;
                        Sys.SysCamBinNumber =       S.SysCamBinNumber;
                        Sys.SysCamPixelHeight =     S.SysCamResolution(1)/S.SysCamBinNumber;
                        Sys.SysCamPixelWidth =      S.SysCamResolution(2)/S.SysCamBinNumber;
        end
        if isfield(S, 'SysCamMain') 
            Sys.SysIdentifier = [S.SysCamMain '_' S.SysCamDeviceName];
            switch Sys.SysIdentifier
                case 'PointGrey_Grasshopper3 GS3-U3-23S6M'
                case 'Thorlabs_CS2100M-USB'
                        Sys.SysCamFrameHeight1st =  0;  % width first
                    if Tm.RunningSource == 'D'
                        Sys.ProcPixelBinNum =	    3;
                    end
                otherwise                                  
                    disp('unrecognizable camera')
            end
        end
%     S.SysCamFrameRate;
%     S.SysCamBinNumber
%     S.SysCamResolution
        Sys.SysCamFramePerTrial =	S.TrlDurTotal * Sys.SysCamFrameRate;
        Tm.SesTrlNumTotal =         length(S.SesTrlOrderVec);
    % Proc Parameters initialization for Spatial & Temporal Binning  
    P.ProcFrameRate =       Sys.ProcFrameRate;
    P.ProcFrameBinNum =     Sys.SysCamFrameRate/P.ProcFrameRate;  
    P.ProcFramePerTrial =	S.TrlDurTotal * P.ProcFrameRate;   
    P.ProcFrameNumTotal =	S.SesFrameTotal / P.ProcFrameBinNum;   
    
    P.ProcPixelBinNum =     Sys.ProcPixelBinNum;
    P.ProcCamPixelHeight =	Sys.SysCamPixelHeight/P.ProcPixelBinNum;
    P.ProcCamPixelWidth =	Sys.SysCamPixelWidth /P.ProcPixelBinNum;
    % Proc data are foced to maintain a 16:10 W/H ratio 
    %   for a consistent later visualization
    if P.ProcCamPixelWidth>(P.ProcCamPixelHeight*16/10) % original too wide
        P.ProcPixelHeight =     P.ProcCamPixelHeight;
        P.ProcPixelWidth =      round(P.ProcCamPixelHeight*16/10);
    else                                                % original too high
        P.ProcPixelHeight =     round(P.ProcCamPixelWidth*10/16);
        P.ProcPixelWidth =      P.ProcCamPixelWidth;
    end
    
	P.RawMeanPixel =	zeros(1, S.SesFrameTotal);
    P.RawMeanPower =	zeros(1, S.SesFrameTotal);                                
    P.ProcMeanPixel =	zeros(1, P.ProcFrameNumTotal);
    P.ProcMeanPower =	zeros(1, P.ProcFrameNumTotal);    
    P.ProcDataMat =     uint32(ones(...    
                                    S.SesCycleNumTotal,...
                                    S.TrlNumTotal,...
                                    P.ProcPixelHeight,...
                                    P.ProcPixelWidth,...
                                    P.ProcFramePerTrial...
                                    ));   
	% "ones", not "zeros": 0s at the edge would mess up normalization later
	P.ProcCamHeightIndex = (1:P.ProcPixelHeight)+round((P.ProcCamPixelHeight- P.ProcPixelHeight)/2);
	P.ProcCamWidthIndex =  (1:P.ProcPixelWidth) +round((P.ProcCamPixelWidth - P.ProcPixelWidth )/2);
% 	P.ProcDataMatHeightIndex =  (1:P.ProCamPixelHeight) + ...
%                                 round((P.ProcPixelHeight-P.ProcCamPixelHeight)/2);
% 	P.ProcDataMatWidthIndex =   (1:P.ProcCamPixelWidth) + ...
%                                 round((P.ProcPixelWidth -P.ProcCamPixelWidth )/2);
	% Patch the dropped frames (for Thorlabs sCMOS)
        Tm.esc = PatchFrame;  

    % Read data
    if ~Tm.esc
    Tm.fid =            fopen(Tm.filename);
    for j = 1:S.SesCycleNumTotal
        for k = 1:S.TrlNumTotal
            m = (j-1)*S.TrlNumTotal + k;
            %% Update GUI
            waitbar(m/Tm.SesTrlNumTotal, Tm.hWaitbar,...
                ['finishing ',...
                sprintf('%d out of %d total trials in the session',...
                    m, Tm.SesTrlNumTotal)] );       
            %% Read Data Batch  
            Tm.DataRaw = 	fread(Tm.fid, [...
                Sys.SysCamPixelHeight * Sys.SysCamPixelWidth, ...
                Sys.SysCamFramePerTrial],...
                'uint16');
            %% Frame #, Trial order # location        
            Tm.RecFramesCurrent =    ((m-1)*	Sys.SysCamFramePerTrial +1):...
                                    (m*     Sys.SysCamFramePerTrial);
            Tm.ProcFramesCurrent =   ((m-1)*	P.ProcFramePerTrial +1):...
                                    (m*     P.ProcFramePerTrial);        
            Tm.TrialOrder =          S.SesTrlOrderVec(m);            
            %% Image Processing
            Tm.PixelMeanRaw =        mean(Tm.DataRaw, 1);
            Tm.PixelMeanBinned =     mean( reshape(...
                                                Tm.PixelMeanRaw,...
                                                P.ProcFrameBinNum,...
                                                P.ProcFramePerTrial), 1 );
            P.RawMeanPixel(Tm.RecFramesCurrent) =    Tm.PixelMeanRaw;
            P.ProcMeanPixel(Tm.ProcFramesCurrent) =  Tm.PixelMeanBinned;              
            if Sys.SysCamFrameHeight1st
                Tm.ImageS0 =         reshape(Tm.DataRaw,...  
                    P.ProcPixelBinNum,     P.ProcCamPixelHeight, ...
                    P.ProcPixelBinNum,     P.ProcCamPixelWidth, ...
                    P.ProcFrameBinNum,     P.ProcFramePerTrial);
                Tm.ImageS1 =         Tm.ImageS0;
            else
                Tm.ImageS0 =         reshape(Tm.DataRaw,...  
                    P.ProcPixelBinNum,     P.ProcCamPixelWidth, ...
                    P.ProcPixelBinNum,     P.ProcCamPixelHeight, ...
                    P.ProcFrameBinNum,     P.ProcFramePerTrial);
                Tm.ImageS1 =         permute(Tm.ImageS0, [3 4 1 2 5 6]); 
            end 
            Tm.ImageS2 =         sum(Tm.ImageS1, 1);  
            Tm.ImageS3 =         sum(Tm.ImageS2, 3); 
            Tm.ImageS4 =         sum(Tm.ImageS3, 5);
            Tm.ImageS5 =         squeeze(Tm.ImageS4);
            
            P.ProcDataMat(j, Tm.TrialOrder, :, :, :) =...
            	uint32(Tm.ImageS5(	P.ProcCamHeightIndex, ...
                                 	P.ProcCamWidthIndex, :));
            % P.ProcDataMat Dimension: 
            %   1:Cycle;    2:Trial;    3:Height;   4:Width;    5:Frame;                         
        end    
    end
    % Power Processing
        %         P.RawMeanPower =    mean(S.SesPowerMeter, 2)';
        %         P.ProcMeanPower =   mean(reshape(P.RawMeanPower,...
        %                                     P.ProcFrameBinNum,...
        %                                     P.ProcFrameNumTotal), 1 );
    % Show Figure
        Tm.timeraw =	(1:S.SesFrameTotal)/Sys.SysCamFrameRate;
        Tm.timebin =	(1:P.ProcFrameNumTotal)/P.ProcFrameRate;
        figure(     'Name',                 Tm.FileName{i},...
                    'Color',                0.95*[1 1 1]);
    % Ax1, Temporal trace of the entire session, averaged across all pixels
        Tm.hAx(1) = subplot(2,1,1);
            Tm.ColorOrder = get(gca, 'ColorOrder');
            Tm.ColorOrder = Tm.ColorOrder(2,:);
            set(Tm.hAx(1),...
                    'ColorOrder',           Tm.ColorOrder,...
                    'Toolbar',              [],...
                    'XLim',                 [0 max(Tm.timeraw)],...
                    'YLim',                 8*[-1 1],...
                    'NextPlot',             'add');
            Tm.hLineRaw =	plot( ...
                Tm.timeraw, 100*(P.RawMeanPixel/mean(P.RawMeanPixel)-1),...
                    'LineWidth',            0.25);
                Tm.hLineRaw.Color(4) =      0.3;   
            Tm.hLineBin =	plot( ...
                Tm.timebin, 100*(P.ProcMeanPixel/mean(P.ProcMeanPixel)-1),...
                    'LineWidth',            0.75);
            Tm.hLineRaw.Color(4) =          0.8;   
        title(Tm.hAx(1),    Tm.FileName{i},...
                    'Interpreter',          'none');
        xlabel(Tm.hAx(1),                   'Time (sec)');
        ylabel(Tm.hAx(1),               {   'Pixel Mean (%)',...
                                            sprintf('Baseline = %5.1f',...
                                                mean(P.RawMeanPixel)) },...
                    'ButtonDownFcn',        [...
                                            'h=gcbo;  hax=h.Parent; ',...
                                            'ylim=hax.YLim;   ylim=ylim*2; ',...
                                            'if ylim(2)>20; ylim=0.125*[-1 1]; end; '...
                                            'hax.YLim=ylim; '
                                                ]);
    % Ax2, Trial-averaged temporal trace of all pixels
        Tm.ProcDataHWF =     squeeze(mean(mean(P.ProcDataMat, 1), 2));
        Tm.ProcDataHWpre =   squeeze(mean(Tm.ProcDataHWF(...
            :,:,1:round(S.TrlDurPreStim*P.ProcFrameRate)),3));
        Tm.ProcDataHWFnorm = Tm.ProcDataHWF./...
            repmat(Tm.ProcDataHWpre,1,1,size(Tm.ProcDataHWF,3));
        Tm.ProcDataPFprec =  (reshape(Tm.ProcDataHWFnorm, ...
            size(P.ProcDataMat,3)*size(P.ProcDataMat,4), [])-1)*100;

        Tm.hAx(2) = subplot(2,1,2);
        plot( (1:size(Tm.ProcDataPFprec,2))/P.ProcFrameRate, Tm.ProcDataPFprec' )
        set(gca,    'XTick',                S.TrlDurPreStim+[0 S.TrlDurStim]);
        set(gca,    'XGrid',                'on');
        xlabel(Tm.hAx(2),                   'Trial time (sec)');
        ylabel(Tm.hAx(2),                   '\DeltaF/F (%)');
%         ,...
%                     'VerticalAlignment',    'middle');
    % Save "P"
    save([Tm.filename(1:end-4),...
        sprintf('_%dx%d@%dfps', P.ProcPixelHeight, P.ProcPixelWidth, P.ProcFrameRate),...
        '_P1.mat'], '-STRUCT', 'P', '-v7.3');     
    fclose(Tm.fid);
    end
end
%% Clean Up
close(Tm.hWaitbar);
disp('All files are processed');
clear P Tm Sys
return;

%% Patch Thorlabs Scientific Camera's Dropped Frames
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function esc = PatchFrame
global S Tm Sys

%% find missing frame, modify .mat
% PatchRule = 'FrameTimeStamp';
PatchRule = 'FrameNum';
switch PatchRule(6) % according to the frame num (N) or timestamp (T)
    case 'N';   indexFmiss = find(S.SesFrameNum == 0);
    case 'T';   indexFmiss = find(double(S.SesTimestamps(:,1))==0);
                S.SesFrameNum(indexFmiss) = 0;
end
if isempty(indexFmiss)   % no missing frame
    esc = 0;    return;
elseif length(indexFmiss)> 20
    fprintf('missing %d frames, too many, escaped!\n\n', length(indexFmiss));
	% save the original files
    namestr = sprintf('_%d_missingframes_', length(indexFmiss));
        movefile(    Tm.filename, ...
                    [Tm.filename(1:end-4) namestr '.rec']);
        movefile(   [Tm.filename(1:end-4) '.mat'], ...
                    [Tm.filename(1:end-4) namestr '.mat']);
    esc = 1;    return;
else
    esc = 0;
end                         % forward is for patch the missing frames
% available_frame = S.SesFrameNum;
indexFlast = find(([1 S.SesFrameNum(1:end-1)'] - S.SesFrameNum')>0)-1;
indexFnext = find(([S.SesFrameNum(2:end)' length(S.SesFrameNum)+1] - S.SesFrameNum')>1)+1;
unitperframe = Sys.SysCamPixelHeight * Sys.SysCamPixelWidth;
disp(['missing frames#: ' sprintf('%d ', indexFmiss)]);
% fprintf('\n');
namestr = [ sprintf('_%d_missingframes_', length(indexFmiss))...
            sprintf('#%d',indexFmiss)    ];
%% Save Original files & ...
    S = load([Tm.filename(1:end-4) '.mat']);	% load S (Saved from recording)
    try 
        S = S.S;
    catch
    end
movefile(    Tm.filename, ...
            [Tm.filename(1:end-4) namestr '.rec']);
movefile(   [Tm.filename(1:end-4) '.mat'], ...
            [Tm.filename(1:end-4) namestr '.mat']);
fid_ori = fopen([Tm.filename(1:end-4) namestr '.rec']);
fid_ptd = fopen( Tm.filename, 'w');
%% Patch the ends if needed
if indexFmiss(1) == 1
    % read the current "next" frame but also as the "0" frame
    indexCl =   indexFlast(1);
    frameCl =   double(fread(fid_ori, [unitperframe, 1], 'uint16'));
    % the current "next" frame;
    indexCn =   indexFnext(1);
    frameCn =   frameCl;
end
for i = 1:length(S.SesFrameNum)
    % read frame
    if      ismember(i, indexFlast) 
        if ~ismember(i, indexFnext)	% last frame before gap, but not read yet
            indexCl =   i;
            frameCl =	double(fread(fid_ori, [unitperframe, 1], 'uint16'));
        else                        % last frame before gap, but already read    
            indexCl =   i;
            frameCl =	frameCn;    % as the "next" frame for the last gap                                   
        end
            indexCn =   indexFnext( find(indexFnext>i,1) );
        if indexCn > length(S.SesFrameNum)
            frameCn =	frameCl;    % ending frame is missing
        else                        % read the "next" frame after the gap
            frameCn =	double(fread(fid_ori, [unitperframe, 1], 'uint16'));
        end
        frame =	frameCl;
    elseif  ismember(i, indexFnext) % pure "next" frame after a gap
        frame = frameCn;
    elseif  ismember(i, indexFmiss) % missed frame
        frame = frameCl*(i-indexCl)/(indexCn-indexCl) + ...
                frameCn*(indexCn-i)/(indexCn-indexCl); % patch the frame
                    S.SesFrameNum(i) = i;
        fprintf('frame#%d is patched from the "last" frame #%d and the "next" frame #%d\n',...
                i, indexCl, indexCn);
    else                            % ordinary frame
        frame =         double(fread(fid_ori, [unitperframe, 1], 'uint16'));
    end
    % write frame
    fwrite(fid_ptd, uint16(frame), 'uint16');
end
%% Finish writing and saving
fclose(fid_ori);
fclose(fid_ptd);
save([Tm.filename(1:end-4), '.mat'], '-STRUCT', 'S', '-v7.3');
fprintf('\n');
