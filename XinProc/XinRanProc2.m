function XinRanProc2(varargin)
% Xintrinsic preProcessingDATA BINNNING

global S P Tm Sys
% P:    Processed, To be saved
% Tm: 	Temporary
% Sys:  System parameters, if not in "S" yet
P = [];     Tm =[];     Sys = []; 

% P.RecCanvasHeight =     300;
% P.RecCanvasWidth =      480;
% System: Default (if not already specified in the "S")
    Tm.SysDeft.SysCamFrameRate =	80;
    Tm.SysDeft.SysCamBinNumber =	4;
    Tm.SysDeft.SysCamPixelHeight =	300;
    Tm.SysDeft.SysCamPixelWidth =	480;
        Tm.SysDeft.ProcPixelBinNum =	4;
        Tm.SysDeft.ProcFrameRate =      5;
% System: FLIR/PointGrey GS3 
    Tm.SysFlir.SysCamFrameRate =	80;
    Tm.SysFlir.SysCamBinNumber =	4;
    Tm.SysFlir.SysCamPixelHeight =	300;
    Tm.SysFlir.SysCamPixelWidth =	480;
        Tm.SysFlir.ProcPixelBinNum =	4;
        Tm.SysFlir.ProcFrameRate =      5;
%             Tm.SysFlir.ProcPixelBinNum =	1;
            
% System: Thorlabs sCMOS
    Tm.SysThor.SysCamFrameRate =	20;
%     Tm.SysThor.SysCamBinNumber =	4;
    Tm.SysThor.SysCamBinNumber =	6;
    Tm.SysThor.SysCamPixelHeight =	270;
    Tm.SysThor.SysCamPixelWidth =	480;
        Tm.SysThor.ProcPixelBinNum =	3;
        Tm.SysThor.ProcFrameRate =      5;

%% Get preprocessed ('*.rec') file
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
else                    % Calling from another script
    Tm.RunningSource =   'S';
    [Tm.PathName, Tm.FileName, FileExt] = fileparts(varargin{1});
    Tm.PathName =        [Tm.PathName, '\'];
    Tm.FileName =        {[Tm.FileName, FileExt]};
end
disp(['Xintrinsic Processing Stage 1 (spatiotemporal binning) is about to start on ' ...
    num2str(length(Tm.FileName)) ' files']);

%% DATA Preprocessing for each file (Binning)
Tm.hWaitbar =	waitbar(0, 'processing');
for i = 1: length(Tm.FileName)
    % Load 'S'
    Tm.filename = [Tm.PathName, Tm.FileName{i}];
    load([Tm.filename(1:end-3) 'mat']);  
    disp([  'Processing: "', Tm.FileName{i}, ...
            '" with the sound: "', S.SesSoundFile, '"']);
	% Default Paremeters (for files older than 2020/11/27)
                                                    Sys = Tm.SysDeft;
	switch [S.SysCamMain '_' S.SysCamDeviceName]
       case 'PointGrey_Grasshopper3 GS3-U3-23S6M';  Sys = Tm.SysFlir;
       case 'Thorlabs_CS2100M-USB';                 Sys = Tm.SysThor;
        otherwise;                                  disp('unrecognizable camera')
	end
    if isfield(S, 'SysCamFrameRate')    % overwrite if available (for files after 2020/11/27)
        Sys.SysCamFrameRate =       S.SysCamFrameRate;
        Sys.SysCamBinNumber =       S.SysCamBinNumber;
        Sys.SysCamPixelHeight =     S.SysCamResolution(1)/S.SysCamBinNumber;
        Sys.SysCamPixelWidth =      S.SysCamResolution(2)/S.SysCamBinNumber;
    end
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
%     P.ProcPixelHeight =     P.RecCanvasHeight/P.ProcPixelBinNum;
%     P.ProcPixelWidth =      P.RecCanvasWidth /P.ProcPixelBinNum;
    
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
            
            switch [S.SysCamMain '_' S.SysCamDeviceName]
               case 'PointGrey_Grasshopper3 GS3-U3-23S6M'
                    Tm.ImageS0 =         reshape(Tm.DataRaw,...  
                        P.ProcPixelBinNum,     P.ProcCamPixelHeight, ...
                        P.ProcPixelBinNum,     P.ProcCamPixelWidth, ...
                        P.ProcFrameBinNum,     P.ProcFramePerTrial);
                    Tm.ImageS1 =         Tm.ImageS0;
                case 'Thorlabs_CS2100M-USB'
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
        figure(     'Name',         Tm.FileName{i});
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
%         [Tm.hAx,~,~] =	plotyy(	Tm.timeraw,      P.RawMeanPower, ...
%                                 Tm.timeraw,      P.RawMeanPixel);
%         xlabel(Tm.hAx(1),        'Time (sec)');
%         ylabel(Tm.hAx(1),        'Power Mean (volt)');
%         ylabel(Tm.hAx(2),        'Pixel Mean (ADU)');
%         subplot(2,1,2);
%         [Tm.hAx, Tm.hP1, Tm.hP2] = ...
%                         plotyy(	Tm.timebinned,   P.ProcMeanPower, ...
%                                 Tm.timebinned,   P.ProcMeanPixel);    
        % Tm.hP2.LineWidth =       2;                     
%         xlabel(Tm.hAx(1),        'Time (sec)');
%         ylabel(Tm.hAx(1),        'Power Mean (volt)');
%         ylabel(Tm.hAx(2),        'Pixel Mean (ADU)');
    % Save "P"
    save([Tm.filename(1:end-4),...
        sprintf('_%dx%d@%dfps', P.ProcPixelHeight, P.ProcPixelWidth, P.ProcFrameRate),...
        '_P1.mat'], 'P', '-v7.3');     
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
switch PatchRule(6)
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
save([Tm.filename(1:end-4), '.mat'], 'S', '-v7.3');
fprintf('\n');
