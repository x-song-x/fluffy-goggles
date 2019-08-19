 % Xintrinsic Trial Based Session 
clear all
% [F.FileName, F.PathName, F.FilterIndex] = uigetfile(...
%     'Z:\2018.03 T2 (Marmoset 80Z, Xintrinsic, Green & Fluo)\*_P1.mat',...
%     'Select a "_P1.mat" file to process');

[F.FileName, F.PathName, F.FilterIndex] = uigetfile(...
    'W:\*_P1.mat',...
    'Select a "_P1.mat" file to process');
% [F.FileName, F.PathName, F.FilterIndex] = uigetfile(...
%     'D:\Test_Imaging\2018.03 T2 (Marmoset 80Z, Xintrinsic, Green & Fluo)\*_P1.mat',...
%     'Select a "_P1.mat" file to process');
if F.FilterIndex == 0
    clear F;
    return
end
if iscell(F.FileName) == 0  % single file selected
    F.FileName = {F.FileName};
end

disp(['Xintrinsic Processing Stage 2 on Tones starts on the session:', F.FileName{1}]);
    
%% Load File
Xin.T.filename = [F.PathName, F.FileName{1}];      
load([Xin.T.filename(1:end-7) '.mat']);         % load S
load([Xin.T.filename(1:end-4) '.mat']);         % load P
disp([  'Processing: "', F.FileName{1}, ...
        '" with the sound: "', S.SesSoundFile, '"']);
% S.TrlNumberTotal =          S.TrlNumberTotal*3;
    
%% Common Parmateters  
global R T

% Figure
if S.TrlNumTotal>8
    T.ImageMag =            1.6;
else    
    T.ImageMag =            2;
end
T.SpecMag =                 3;

T.AxesSide =                [60 90];    % Fige side
T.AxesSB =                  10;         % Axes, Space in Between
T.AxesSCB =                 60;         % Sxes, Space of ColorBar

T.N_IntColorLim =           [0 1];
T.N_StdColorLim =           [0.0001,  0.1];
T.N_StdColorLimLog =        log10(T.N_StdColorLim);
T.N_StdColorTickLog =       T.N_StdColorLimLog(1):1:T.N_StdColorLimLog(2);
T.N_StdColorTickLabels =	cellfun(@num2str, num2cell(10.^T.N_StdColorTickLog),...
                            'UniformOutput',    false);               
T.RefFrameStart =           squeeze(P.ProcDataMat(1,1,:,:,1));             
T.RefFrameEnd =             squeeze(P.ProcDataMat(end,end,:,:,end));
R.RefFrame =                T.RefFrameStart + T.RefFrameEnd;
R.RefFrame =                R.RefFrame / max(max(R.RefFrame));     
    T.hFig(1) = figure(...
                    'Name',         ['Determine the ROI in the session "', F.FileName{1}(1:end-7), '"'],...
                    'Units',        'pixels',...  
                    'Position',     [   10                      10....
                                        T.AxesSide(1)*2+P.ProcPixelWidth*5 ...
                                        T.AxesSide(2)*2+P.ProcPixelHeight*5 ]);
    T.hFig1Axes(1) = axes(...
                    'Parent',       T.hFig(1),...
                    'Units',        'pixels',...  
                    'Position',     [   T.AxesSide(1)           T.AxesSide(2)...
                                        P.ProcPixelWidth*5      P.ProcPixelHeight*5 ]);
    imshow(R.RefFrame,...
                    'InitialMagnification',         500);    
    title(                       	'Drag to position the ROI, double click on the circle to finish');
    T.hFig1Axes1ROI = imellipse(gca, [23 0 76 76]);
    wait(T.hFig1Axes1ROI);
    title(                          'Done, start calculating...');
    pause(0.1);

% Data & Numbers 
% Pixel
R.N_Ph =            P.ProcPixelHeight;      % Number_PixelHeight
R.N_Pw =            P.ProcPixelWidth;       % Number_PixelWidth
R.N_Pt =            R.N_Ph * R.N_Pw;        % Number_PixelTotal, proc

% Frame, Trial, Cycle
R.N_Ft =            P.ProcFrameNumTotal;                            % FrameTotal
R.N_Fpc =           R.N_Ft / S.SesCycleNumTotal;                    % FramePerCycle
R.N_Fpt =           R.N_Fpc / S.TrlNumTotal;                        % FramePerTrial

R.N_Ftpreoff =      round(  S.TrlDurPreStim *               P.ProcFrameRate); % Number_FrameTrialPrestimOff
R.N_Ftstimon =      R.N_Ftpreoff + 1;
R.N_Ftstimoff =     round(( S.TrlDurPreStim+S.TrlDurStim) * P.ProcFrameRate); % Number_FrameTrialStimOff
R.N_Ftposton =      R.N_Ftstimoff + 1;

R.N_Tt =                S.TrlNumTotal;
R.N_Ct =                S.SesCycleNumTotal;
                        
% Region of Interest
R.PhPw_ROIin =          createMask(T.hFig1Axes1ROI);            % ROI in
R.PhPw_ROIout =         ~R.PhPw_ROIin;                          % ROI out
R.Pt_ROIin =            reshape(R.PhPw_ROIin,     R.N_Pt, []);  % ROI in 
R.PtIndex_ROIin =       find(R.Pt_ROIin);
R.Pt_ROIout =           reshape(R.PhPw_ROIout,    R.N_Pt, []);  % ROI out

% Temporal Analysis

% Spectral AnalysisFpt
R.N_Qt =                R.N_Pt;
R.N_Qfc =               int16((1/S.SesSoundDurTotal)/ (80/P.ProcFrameBinNum/R.N_Ft) +1);     % cc
R.N_Qft =               (1/S.TrlDurTotal)/      (80/P.ProcFrameBinNum/R.N_Ft) +1;   
R.Qt_Freqs =            0:  (80/P.ProcFrameBinNum/R.N_Ft):     ...
                            ((R.N_Ft-1)*	80/P.ProcFrameBinNum/R.N_Ft); 
T.PtQt_ROIin =          R.Pt_ROIin *     ones(1,   length(R.Qt_Freqs));    
T.PtQt_ROIout =         R.Pt_ROIout *    ones(1,   length(R.Qt_Freqs));

% Data
T.PtFt_Raw =            reshape(permute(P.ProcDataMat,[2,3,4,5,1]),    R.N_Pt,	R.N_Ft); % aa
R.Name =                'Raw';
R.PtFt_A0 =             T.PtFt_Raw;

%% Power Meter
% interpolate 0s
% T.OneFrt_PMRawZero =    (P.RawMeanPower == 0);
% if sum(P.RawMeanPower == 0) ~=0
%     % if 
% else
%     T.OneFt_PowerRaw =  P.ProcMeanPower;
% end
% T.OneFt_PowerRaw =  P.ProcMeanPower;
% T.OneQt_PowerFFTRaw =   fft(T.OneFt_PowerRaw);
% T.OneQt_PowerFFTAbs =   abs(T.OneQt_PowerFFTRaw)*2/length(R.Qt_Freqs);

    delete(T.hFig(1));
    T.hFig(2) = figure(...
                    'Name',         ['"', F.FileName{1}, '" with the sound: "', S.SesSoundFile, '"'],...
                    'Units',        'pixels',...  
                    'Position',     [   10                      10....
                                        1600                    850]);  

%% Variance Analysis 
T.CtTtFptPhPw_DataRaw =     permute(P.ProcDataMat, [1 2 5 3 4]);

R.Fig2Var{1}.Title =        'Average intensity (% to saturation)';
R.Fig2Var{1}.PhPw_Data =	squeeze(mean(mean(mean(T.CtTtFptPhPw_DataRaw, 1), 2), 3)) / ...
                            (2^12 *4^2 *P.ProcPixelBinNum^2 *P.ProcFrameBinNum);
R.Fig2Var{1}.ColorMap =     'hot';  

R.Fig2Var{2}.Title =        'STD, entire session (ratio)';
R.Fig2Var{2}.PhPw_Data =	squeeze(std(reshape(T.CtTtFptPhPw_DataRaw, R.N_Ft, R.N_Ph, R.N_Pw), 0, 1))./...
                                squeeze(mean(mean(mean(T.CtTtFptPhPw_DataRaw, 1), 2), 3)) ;
R.Fig2Var{2}.ColorMap =     'parula';

R.Fig2Var{3}.Title =        'STD, across repetition cycles (ratio)';
R.Fig2Var{3}.PhPw_Data =	squeeze(std(mean(mean(T.CtTtFptPhPw_DataRaw, 2), 3), 0, 1))./...
                                squeeze(mean(mean(mean(T.CtTtFptPhPw_DataRaw, 1), 2), 3)) ;
R.Fig2Var{3}.ColorMap =     'parula';    

R.Fig2Var{4}.Title =        'STD, across different trials (ratio)';
R.Fig2Var{4}.PhPw_Data =	squeeze(std(mean(mean(T.CtTtFptPhPw_DataRaw, 1), 3), 0, 2))./...
                                squeeze(mean(mean(mean(T.CtTtFptPhPw_DataRaw, 1), 2), 3)) ;
R.Fig2Var{4}.ColorMap =     'parula';    

R.Fig2Var{5}.Title =        'STD, across frames within each trial (ratio)';
R.Fig2Var{5}.PhPw_Data =	squeeze(std(mean(mean(T.CtTtFptPhPw_DataRaw, 1), 2), 0, 3))./...
                                squeeze(mean(mean(mean(T.CtTtFptPhPw_DataRaw, 1), 2), 3)) ;
R.Fig2Var{5}.ColorMap =     'parula'; 
                                                                  
    for j = 1:5
        T.AxesNumH =    j;
        T.AxesNumV =	1;
        T.hFig2AxesVar(j) = axes(...
                    'Parent',       T.hFig(2),...
                    'Units',        'pixels',...  
                    'Position',     [   T.AxesSide(1) + (T.AxesSCB + R.N_Pw*T.ImageMag)*(T.AxesNumH-1), ...
                                        T.AxesSide(2) +  T.AxesSB,...
                                        R.N_Pw*T.ImageMag,    R.N_Ph*T.ImageMag],...
                    'Tag',          [num2str(j), 'Var']);
        if strcmp(R.Fig2Var{j}.Title(1:3), 'STD')
            imagesc(    log10(      R.Fig2Var{j}.PhPw_Data)    );
        else
            imagesc(                R.Fig2Var{j}.PhPw_Data     );
        end
        set(gca,    'XTick',        []);
        set(gca,    'YTick',        []);
        colormap(   T.hFig2AxesVar(j), R.Fig2Var{j}.ColorMap);
        if strcmp(R.Fig2Var{j}.Title(1:3), 'STD')
            caxis(                  T.N_StdColorLimLog);
        else 
            caxis(                  T.N_IntColorLim);
        end
        T.hFig2VarColorbar(j) = colorbar(...
                    'Units',        'pixels',...
                    'Position',     [   T.AxesSide(1) + (T.AxesSCB + R.N_Pw*T.ImageMag)*(T.AxesNumH-1) + R.N_Pw*T.ImageMag + 10, ...
                                        T.AxesSide(2) +  T.AxesSB,...
                                        10                      R.N_Ph*T.ImageMag]);                     
        if strcmp(R.Fig2Var{j}.Title(1:3), 'STD')
            set(T.hFig2VarColorbar(j),...
                    'Ticks',        T.N_StdColorTickLog,...
                    'TickLabels',   T.N_StdColorTickLabels);
        else
            set(T.hFig2VarColorbar(j),...
                    'Ticks',        0:0.2:1,...
                    'TickLabels',   {'0%', '20', '40', '60', '80', '100'});
            
        end
        title(R.Fig2Var{j}.Title);
        xlabel( {[  'Max for all:  ',	sprintf('%5.2f%%', max(max(R.Fig2Var{j}.PhPw_Data))*100 ) ],...
                 [  'Mean inside: ',	sprintf('%5.2f%%', sum(sum(R.Fig2Var{j}.PhPw_Data.*R.PhPw_ROIin))/sum(R.Pt_ROIin)*100 ) ],...
                 [  'Min for all:   ',	sprintf('%5.2f%%', min(min(R.Fig2Var{j}.PhPw_Data))*100 ) ]} );
    end

%% Trial Analysis
switch R.N_Tt
%         case 5;     T.TrialOrder = [5 3 1 4 2];
%         case 7;     T.TrialOrder = [7 4 1 5 2 6 3];
    otherwise;  T.TrialOrder = 1:R.N_Tt;
end

R.PtOne_MeanForEachPixel =	mean(R.PtFt_A0, 2);
R.PtFt_NormSes =           R.PtFt_A0./(R.PtOne_MeanForEachPixel*...
                                ones(1, R.N_Ft)) - 1;
R.FptTtCtPhPw_NormSes =	permute( reshape(R.PtFt_NormSes, ...
                                    R.N_Ph, ...
                                    R.N_Pw, ...
                                    R.N_Fpt, ...
                                    R.N_Tt, ...
                                     R.N_Ct), [3, 4, 5, 1, 2]);
if R.N_Ftpreoff >0
    R.OneTtCtPhPw_PreMean =    mean( R.FptTtCtPhPw_NormSes(...
                                        1:R.N_Ftpreoff, :, :, :, :), 1);    % with pre-stim time as baseline
else
    R.OneTtCtPhPw_PreMean =    mean( R.FptTtCtPhPw_NormSes(...
                                        1:end, :, :, :, :), 1);             % continuous, so total average us baseline
end
R.FptTtCtPhPw_NormTrl =	(R.FptTtCtPhPw_NormSes+1)./...
                                (repmat(R.OneTtCtPhPw_PreMean, R.N_Fpt,1,1,1,1)+1) -1;
%     R.FptTtCtPhPw_NormTrl =	R.FptTtCtPhPw_NormSes;
R.FptTtPhPw_NormTrlM =     squeeze(mean(R.FptTtCtPhPw_NormTrl, 3));
R.FptTtPt_NormTrlM =       reshape(R.FptTtPhPw_NormTrlM,...
                                    R.N_Fpt, ...
                                    R.N_Tt, ...
                                    R.N_Pt);  

T.TempLimMin =  min(min(min(R.FptTtPt_NormTrlM(:,:,:)))); 
T.TempLimMax =  max(max(max(R.FptTtPt_NormTrlM(:,:,:)))); 

switch F.FileName{1}([15:17 end-15:end-7])
    case 'NIR_Ring_PBS'
        T.length =      60;
        T.PeakF =       18;
        T.Polarity =    -1;
        T.max =         0.05*ones(1, R.N_Tt);
    case 'NIR_Pola_PBS'
        T.length =      60;
        T.PeakF =       18;
        T.Polarity =    -1;
        T.max =         0.05*ones(1, R.N_Tt);
    case 'Far_Pola_PBS'
        T.length =      60;
        T.PeakF =       18;
        T.Polarity =    -1;
        T.max =         0.05*ones(1, R.N_Tt);   
    case 'FRe_Pola_PBS'
        T.length =      60;
        T.PeakF =       18;
        T.Polarity =    -1;
        T.max =         0.05*ones(1, R.N_Tt);
    case 'Red_Pola_PBS'
        T.length =      60;
        T.PeakF =       18;
        T.Polarity =    1;
        T.max =         0.05*ones(1, R.N_Tt);
    case 'Yel_Pola_PBS'
        T.length =      60;
        T.PeakF =       18;
        T.Polarity =    1;
        T.max =         0.05*ones(1, R.N_Tt);
    case 'Amb_Pola_PBS'
        T.length =      60;
        T.PeakF =       18;
        T.Polarity =    1;
        T.max =         0.05*ones(1, R.N_Tt);
    case 'Gre_Pola_PBS'
        T.length =      100;
        T.PeakF =       18;
        T.Polarity =    -1; 
        T.max =         0.05*ones(1, R.N_Tt);
    case 'Blu_Pola_PBS'
        T.length =      60;
        T.PeakF =       18;
        T.Polarity =    -1; 
        T.max =         0.05*ones(1, R.N_Tt);
    case 'Blu_Fluo_GFP'
        T.length =      100;
        T.PeakF =       12;
        T.Polarity =    1;
        T.max =         0.10*ones(1, R.N_Tt);
    otherwise
        T.length =      60;
        T.PeakF =       18;
        T.Polarity =    1;
        T.max =         0.05*ones(1, R.N_Tt);
end  
%     T.max =     max(max( T.TrlNumFrmMVV_NormACM, [], length(size(T.TrlNumFrmMVV_NormACM)) ));
T.max = T.max/10;

if  strcmp(S.SesSoundFile(1:10),    'TonePipSeq') || ...
    strcmp(S.SesSoundFile(1:11),    'NoisePipSeq') || ...
    strcmp(S.SesSoundFile(1:5),     'Music')    
        T.length =      R.N_Fpt;
end
T.TrlNumFrmMVV_NormACM = T.Polarity *R.FptTtPt_NormTrlM(1:T.length,:,:); 

% Temporal trace
for j = 1:1
    for k = 1:R.N_Tt
        m = T.TrialOrder(k);

        % Axes Temporal Trace 'Average temporal response of a sound cycle';
        T.hFig2AxesTemp(m) = axes(...
                    'Parent',       T.hFig(2),...
                    'Units',        'pixels',...  
                    'Position',     [   T.AxesSide(1)*(m  )+R.N_Pw*(m-1)*T.ImageMag, ...
                                        T.AxesSide(2)*(2  )+R.N_Ph*(1  )*T.ImageMag, ...
                                        R.N_Pw*T.ImageMag,    R.N_Ph*T.ImageMag]); 

        R.PtIndex_STD =        squeeze(std(R.FptTtPt_NormTrlM(:,k,R.PtIndex_ROIin), 1));
        plot(   (1:R.N_Fpt)/P.ProcFrameRate,...
                squeeze( R.FptTtPt_NormTrlM(:,k,R.PtIndex_ROIin) )   );
        set(gca,    'XLim',         [0 R.N_Fpt/P.ProcFrameRate]);    
        if      R.N_Ftpreoff >0 && R.N_Ftposton<R.N_Fpt
            set(gca,'XTick',        [0 R.N_Ftpreoff R.N_Ftstimoff R.N_Fpt]/P.ProcFrameRate); 
        elseif	R.N_Ftpreoff >0 
            set(gca,'XTick',        [0 R.N_Ftpreoff R.N_Fpt]/P.ProcFrameRate);
        elseif	R.N_Ftposton<R.N_Fpt
            set(gca,'XTick',        [0 R.N_Ftstimoff R.N_Fpt]/P.ProcFrameRate);  
        else
            set(gca,'XTick',        [0 R.N_Fpt]/P.ProcFrameRate);
        end
        set(gca,    'XGrid',        'on');       
        set(gca,    'YLim',         T.max(k)*[-1 1],...
                    'YTick',        T.max(k)*[-1 0 1],...
                    'YTickLabel',   {   ['-',   num2str(T.max(k)*100)],...
                                        '0',...
                                                num2str(T.max(k)*100) }); 
        xlabel({['Trial time (s)'],...
                ['Max  STD:  ',	sprintf('%5.2f%%', max(R.PtIndex_STD)*100)],...
                ['Mean STD: ',	sprintf('%5.2f%%', mean(R.PtIndex_STD)*100)] },...
                    'Parent',       gca,...
                    'VerticalAlignment',    'middle');
        ylabel({'Norm. signal (%)','raw polarity',''},...
                    'Parent',       gca,...
                    'VerticalAlignment',    'Middle');
        title('Trial temporal trace');
%             text(R.N_Fpt/P.ProcFrameRate*1.0, T.max(k)* 0.85,...
%                         ['Max  STD: ', sprintf('%5.2f%%', max(R.PtIndex_STD)*100)],...
%                         'HorizontalAlignment',  'right'); 
%             text(R.N_Fpt/P.ProcFrameRate*1.0, T.max(k)*-0.85,...
%                         ['Mean STD: ', sprintf('%5.2f%%', mean(R.PtIndex_STD)*100)],...
%                         'HorizontalAlignment',  'right');  

        % Axes Video of Window        
        T.hFig2AxesVid(m) = axes(...
                    'Parent',       T.hFig(2),...
                    'Units',        'pixels',...  
                    'Position',     [   T.AxesSide(1)*(m+1)+R.N_Pw*(m  )*T.ImageMag, ...
                                        T.AxesSide(2)*(2  )+R.N_Ph*(1  )*T.ImageMag, ...
                                        R.N_Pw*T.ImageMag,    R.N_Ph*T.ImageMag]);
        T.hFig2Vid(m) = imagesc(R.RefFrame,...
                    'Parent',       T.hFig2AxesVid(m));
        T.hFig2VidTitle(m) = title('');
        set(T.hFig2AxesVid(m),'XTick',        []);
        set(T.hFig2AxesVid(m),'YTick',        []);            
        xlabel('Response Video, adjusted polarity (%)',...
                    'Parent',       gca,...
                    'VerticalAlignment',    'Top');
        colormap(   T.hFig2AxesVid(m), 'jet');
        caxis(                  [-1 1]);
        T.hFig2VidColorbar(m) = colorbar(...
                    'Parent',       T.hFig(2));
        set(T.hFig2VidColorbar(m),...
                    'Units',        'pixels',...
                    'Position',     [   T.AxesSide(1)*(m+1)+R.N_Pw*(m+1)*T.ImageMag+10 ...
                                        T.AxesSide(2)*2+R.N_Ph*T.ImageMag,...
                                        10                      R.N_Ph*T.ImageMag],...
                    'Ticks',        [-1 0 1],...
                    'TickLabels',   {   ['-', num2str(T.max(k)*100) '%'],...
                                        '0%',...
                                        [num2str(T.max(k)*100) '%'] });              
    end
end
pause;
% Video
for j = [1:T.length T.PeakF]
    for k = 1:R.N_Tt
        m = T.TrialOrder(k);
        if S.TrlNumTotal == 1
            T.Frame = reshape(T.TrlNumFrmMVV_NormACM(j,:)/T.max(1), ...
                                R.N_Ph, R.N_Pw);
        else
            T.Frame = squeeze(reshape(T.TrlNumFrmMVV_NormACM(j,k,:)/T.max(k), ...
                                R.N_Ph, R.N_Pw));
        end
        set(T.hFig2Vid(m),...
                'cData',        T.Frame);
        set(T.hFig2VidTitle(m),...
                'String',       [sprintf('Trial time: %5.1f s', j/5)] );
    end
    pause(0.2);
end

bb = squeeze(reshape(T.TrlNumFrmMVV_NormACM(T.PeakF,:,:), ...
            R.N_Tt, R.N_Ph, R.N_Pw));

% 	aa = reshape(T.Polarity *R.FptTtPt_NormTrlM(:,:,:), ...
%         R.N_Fpt,	R.N_Tt,...
%        	R.N_Ph,     R.N_Pw);

%     [~, II] = sort(T.TrialOrder);
%     bb = aa(:,II,42, 39);
%     bb = aa(:,II,43, 27);
%     figure
%     plot(bb, 'linewidth', 3);
%     set(gca,    'ylim', 0.05*[ -1 1]);
%     legend('0.2 sec', '0.4 sec', '0.6 sec', '0.8 sec', '1.0 sec', 'Location', 'NorthEast');  
%     legend('1 sec', '2 sec', '3 sec', '4 sec', '5 sec', 'Location', 'NorthEast');    

% figure
% pnum = [29, 46];
% plot(aa08(:, 1, pnum(1), pnum(2)), 'linewidth', 3);
% hold on;
% plot(aa10(:, 1, pnum(1), pnum(2)), 'linewidth', 3);
% plot(aa15(:, 1, pnum(1), pnum(2)), 'linewidth', 3);
% plot(aa20(:, 1, pnum(1), pnum(2)), 'linewidth', 3);
% plot(aa30(:, 1, pnum(1), pnum(2)), 'linewidth', 3);
% plot(aa40(:, 1, pnum(1), pnum(2)), 'linewidth', 3);
% legend('8 sec', '10 sec', '15 sec', '20 sec', '30 sec', '40 sec', 'Location', 'NorthEast');  

% aa = reshape(T.Polarity *R.FptTtPt_NormTrlM(:,:,:), ...
%         R.N_Fpt,	R.N_Tt,...
%        	R.N_Ph,     R.N_Pw);
% figure
% pnum = [30  43];
% pnum = [34  38];
% plot(aa(:, :, pnum(1), pnum(2)), 'linewidth',3);
% legend( '0.2 sec', '0.4 sec', '0.6 sec', '0.8 sec',...
%         '1.0 sec', '1.2 sec', '1.4 sec', '1.6 sec',...
%         'Location', 'NorthEast'); 

% figure
% pnum = [28, 35];
% plot(aa40(:, 1, pnum(1), pnum(2)), 'linewidth', 3);
% hold on;
% plot(aa30(:, 1, pnum(1), pnum(2)), 'linewidth', 3);
% plot(aa20(:, 1, pnum(1), pnum(2)), 'linewidth', 3);
% plot(aa15(:, 1, pnum(1), pnum(2)), 'linewidth', 3);
% plot(aa10(:, 1, pnum(1), pnum(2)), 'linewidth', 3);

% plot(aa08(:, 1, pnum(1), pnum(2)), 'linewidth', 3);
% plot(aa06(:, 1, pnum(1), pnum(2)), 'linewidth', 3);
% plot(aa04(:, 1, pnum(1), pnum(2)), 'linewidth', 3);
% legend( '40 sec', '30 sec', '20 sec', '15 sec', '10 sec',...
%         '08 sec', '06 sec', '04 sec', '02 sec', 'Location', 'NorthEast');
% legend( ' 2 sec', ' 4 sec', ' 6 sec', ' 8 sec',...
%         '10 sec', '15 sec', '20 sec', '30 sec', '40 sec', 'Location', 'NorthEast');  


%     for j = 1: S.TrlNumberTotal
%         subplot(S.TrlNumberTotal, k, (j-1)*k+3);
%         imagesc(squeeze(R.FrameTrlMR_PeakTrl(:,:,j)));
%         caxis([0    0.01]);
%         set(gca,    'XTick',        []);
%         set(gca,    'YTick',        []);
%         colormap jet
%         colorbar
%         title('Peak, within the trial (ratio)');           
%     end
%     figure
%     imagesc(R.FrameM3_StdTrail);
%      [Y I] = max(R.FrameTrlMR_PeakTrl, [], 3);
%     figure
%     imagesc(I)

%% Spectral Analysis
switch F.FileName{1}([15:17 end-15:end-7])
    case 'NIR_Ring_PBS'
        R.PtQt_FFTRaw =        fft(-R.PtFt_NormSes')'; 
        T.PsuedoDelay =             2.6;
    case 'NIR_Pola_PBS'
        R.PtQt_FFTRaw =        fft(-R.PtFt_NormSes')'; 
        T.PsuedoDelay =             2.6;
    case 'Far_Pola_PBS'
        R.PtQt_FFTRaw =        fft(R.PtFt_NormSes')'; 
        T.PsuedoDelay =             2.6;
    case 'FRe_Pola_PBS'
        R.PtQt_FFTRaw =        fft(R.PtFt_NormSes')'; 
        T.PsuedoDelay =             2.6;
    case 'Red_Pola_PBS'
        R.PtQt_FFTRaw =        fft(R.PtFt_NormSes')'; 
        T.PsuedoDelay =             2.6;
    case 'Yel_Pola_PBS'
        R.PtQt_FFTRaw =        fft(R.PtFt_NormSes')'; 
        T.PsuedoDelay =             2.6;
    case 'Amb_Pola_PBS'
        R.PtQt_FFTRaw =        fft(R.PtFt_NormSes')'; 
        T.PsuedoDelay =             2.6;
    case 'Gre_Pola_PBS'
        R.PtQt_FFTRaw =        fft(-R.PtFt_NormSes')'; 
        T.PsuedoDelay =             2.6;
    case 'Blu_Pola_PBS'
        R.PtQt_FFTRaw =        fft(-R.PtFt_NormSes')'; 
        T.PsuedoDelay =             2.6;
    case 'Blu_Fluo_GFP'
        R.PtQt_FFTRaw =        fft(R.PtFt_NormSes')';
        T.PsuedoDelay =             0.8 - 0.8;
    otherwise
        R.PtQt_FFTRaw =        fft(R.PtFt_NormSes')'; 
        T.PsuedoDelay =             2.6;
end   
R.PhPwQt_FFTRaw =      reshape(R.PtQt_FFTRaw,...
                            R.N_Ph, R.N_Pw, length(R.Qt_Freqs));
R.PtQt_FFTAbs =        abs(R.PtQt_FFTRaw)*2/length(R.Qt_Freqs);
R.OneQt_FFTAbsMeanOut= sum(R.PtQt_FFTAbs.*T.PtQt_ROIout)/  sum(R.Pt_ROIout);
R.OneQt_FFTAbsMeanIn =	sum(R.PtQt_FFTAbs.*T.PtQt_ROIin)/   sum(R.Pt_ROIin);
R.OneQt_FFTAbsMaxIn =	max(R.PtQt_FFTAbs.*T.PtQt_ROIin);
R.OneQt_FFTAbsStdIn =	std(R.PtQt_FFTAbs(R.PtIndex_ROIin,:),1);
R.OneQt_FFTAbsMeanPStdIn = R.OneQt_FFTAbsMeanIn + R.OneQt_FFTAbsStdIn;

if R.N_Tt == 1
    T.FFTXTick =    [1/S.SesSoundDurTotal                   80/P.ProcFrameBinNum/2];
else
    T.FFTXTick =	[1/S.SesSoundDurTotal	1/S.TrlDurTotal	80/P.ProcFrameBinNum/2];
end

    % Axes Spectrum
    T.hFig2AxesSpec(1) = axes(...
                'Parent',       T.hFig(2),...
                'Units',        'pixels',...                      
                'Position',     [   T.AxesSide(1)*(1  )+R.N_Pw*(0  )*T.SpecMag, ...
                                    T.AxesSide(2)*(3  )+R.N_Ph*(2  )*T.ImageMag, ...
                                    R.N_Pw*T.SpecMag	R.N_Ph*T.SpecMag],...
                'NextPlot',     'add');
    plot(R.Qt_Freqs, R.OneQt_FFTAbsMeanIn);
    plot(R.Qt_Freqs, R.OneQt_FFTAbsMeanOut);
%     plot(R.Qt_Freqs, T.OneQt_PowerFFTAbs);
    plot(R.Qt_Freqs, R.OneQt_FFTAbsMeanPStdIn, 'b:');
    set(gca,    'XTick',        T.FFTXTick,... 
                'XLim',         [80/P.ProcFrameBinNum/R.N_Ft  80/P.ProcFrameBinNum/2],...
                'YLim',         [0 0.02],...
                'YTick',        0.000:0.005:0.20,...
                'YTickLabel',   {'0.0%', '0.5%', '1.0%', '1.5%', '2.0%'},...
                'XGrid',        'on',...
                'XScale',       'log');
	xlabel({['Frequency (Hz)']},...
                'Parent',       gca,...
                'VerticalAlignment',    'middle');
    title('Spectrum');
%     legend('Inside Mean', 'Outside Mean', 'Power meter', 'Inside Mean+Std',...
%                 'Location',     'Northeast');
    legend('Inside Mean', 'Outside Mean', 'Inside Mean+Std',...
                'Location',     'Northeast');
    legend('boxoff'); 
    
R.PhPw_CycleAmp =      abs(        R.PhPwQt_FFTRaw(:,:,R.N_Qfc) )*2/R.N_Ft;
R.PhPw_CycleAgl =      mod(angle(  R.PhPwQt_FFTRaw(:,:,R.N_Qfc) ), 2*pi);                      
R.PtOne_CycleAmp =     reshape(R.PhPw_CycleAmp,   R.N_Pt, 1);
R.PtOne_CycleAgl =     reshape(R.PhPw_CycleAgl, R.N_Pt, 1);  

%% Prepare the raw hue & sat
    R.PtOne_Hue =       mod(    R.PtOne_CycleAgl - ...
                                    T.PsuedoDelay/S.SesSoundDurTotal*2*pi, 2*pi)/(2*pi);
                            % Compensate the pseudo-delay
if contains(lower(S.SesSoundFile), 'down')
    R.PtOne_Hue =      1 - R.PtOne_Hue;
end
                            % Reverse the hue for DOWN cycle               
% S.TrlDurPreStim =   2.5;
% S.TrlDurStim =      15;
    R.PtOne_Hue =           (R.PtOne_Hue-S.TrlDurPreStim/S.TrlDurTotal) /...
                                (S.TrlDurStim/S.TrlDurTotal);
                            % match the Stimulus ONSET / OFFSET to 0-1
    R.PtOne_Saturation =	R.PtOne_Hue*0 +1;          
    R.PtOne_Value =         R.PtOne_CycleAmp; 

R.PtThree_TuneMap =         hsv2rgb([	0*R.PtOne_Hue,...
                                        0*R.PtOne_Saturation,...
                                        0*R.PtOne_Value]);
R.PhPwThree_TuneMap =       reshape(R.PtThree_TuneMap, R.N_Ph, R.N_Pw,3);

    % Axes: Cycle Tuning Map
    T.hFig2AxesTune = axes(...
                'Parent',       T.hFig(2),...
                'Units',        'pixels',...  
                'Position',     [   T.AxesSide(1)*(2  )+R.N_Pw*(1  )*T.SpecMag ...
                                    T.AxesSide(2)*(3  )+R.N_Ph*(2  )*T.ImageMag, ...
                                    R.N_Pw*T.SpecMag    R.N_Ph*T.SpecMag],...
                'NextPlot',     'add');   
    T.hFig2AxesTuneImage = image(T.hFig2AxesTune, R.PhPwThree_TuneMap);
    set(T.hFig2AxesTune, ...
                'YDir',         'reverse',...
                'XLim',         [1 R.N_Pw],...
                'YLim',         [1 R.N_Ph],...
                'XTick',        [],...
                'YTick',        []);
                     
    % ScaleBar: Hue
    T.hFig2AxesTuneFakeHue = axes(...
                'Parent',       T.hFig(2),...
                'Units',        'pixels',...  
                'Position',     get(T.hFig2AxesTune, 'position'),...
                'Visible',     'off'); 
    colormap(   T.hFig2AxesTuneFakeHue, 'hsv');                     caxis( [0 1]);
    T.hFig2SpecScaleBarHue = colorbar(...
                'Units',        'pixels',...
                'Position',     [   T.AxesSide(1)*(2  )+R.N_Pw*(2  )*T.SpecMag+10, ...
                                    T.AxesSide(2)*(3  )+R.N_Ph*(2  )*T.ImageMag, ...
                                    10                  R.N_Ph*T.SpecMag],...
                'Ticks',        [],...
                'Tag',          'ScaleBarHue',...
                'ButtonDownFcn','XinRanAnalysis2_Sweep_ScaleBar');
	setappdata(T.hFig2SpecScaleBarHue, ...
                'ImageH',       T.hFig2AxesTuneImage);
            
    % ScaleBar: Saturation
    T.hFig2AxesTuneFakeSat = axes(...
                'Parent',       T.hFig(2),...
                'Units',        'pixels',...  
                'Position',     get(T.hFig2AxesTune, 'position'),...
                'Visible',      'off'); 
    colormap(   T.hFig2AxesTuneFakeSat,...
            hsv2rgb([1/3*ones(64,1) (0:1/63:1)' 0.5*ones(64,1)]) );	caxis( [0 1]);
    T.hFig2SpecScaleBarSat = colorbar(...
                'Units',        'pixels',...
                'Position',     [   T.AxesSide(1)*(2  )+R.N_Pw*(2  )*T.SpecMag+40, ...
                                    T.AxesSide(2)*(3  )+R.N_Ph*(2  )*T.ImageMag, ...
                                    10                  R.N_Ph*T.SpecMag],...
                'Ticks',        [],...
                'Tag',          'ScaleBarSat',...
                'ButtonDownFcn','XinRanAnalysis2_Sweep_ScaleBar'); 
	setappdata(T.hFig2SpecScaleBarSat, ...
                'ImageH',       T.hFig2AxesTuneImage);
    
    % ScaleBar: Value
    T.hFig2AxesTuneFakeVal = axes(...
                'Parent',       T.hFig(2),...
                'Units',        'pixels',...  
                'Position',     get(T.hFig2AxesTune, 'position'),...
                'Visible',      'off'); 
    colormap(   T.hFig2AxesTuneFakeVal,  'gray');     caxis( [0 1]);
    T.hFig2SpecScaleBarVal = colorbar(...
                'Units',        'pixels',...
                'Position',     [   T.AxesSide(1)*(2  )+R.N_Pw*(2  )*T.SpecMag+70, ...
                                    T.AxesSide(2)*(3  )+R.N_Ph*(2  )*T.ImageMag, ...
                                    10                  R.N_Ph*T.SpecMag],...
                'Ticks',        [],...
                'Tag',          'ScaleBarVal',...
                'ButtonDownFcn','XinRanAnalysis2_Sweep_ScaleBar');   
	setappdata(T.hFig2SpecScaleBarVal, ...
                'ImageH',       T.hFig2AxesTuneImage);            
	setappdata(T.hFig2AxesTuneImage,    'RawHue',           R.PtOne_Hue);
	setappdata(T.hFig2AxesTuneImage,    'RawSat',           R.PtOne_Saturation);
	setappdata(T.hFig2AxesTuneImage,    'RawVal',           R.PtOne_Value);
    setappdata(T.hFig2AxesTuneImage,    'HueMapOptions', {  'HSLuvCircular',...
                                                            'HSLuvLinear',...
                                                            'HSLuvZigZag'});
    setappdata(T.hFig2AxesTuneImage,    'HueMapOrder',      1);
    setappdata(T.hFig2AxesTuneImage,    'HueMap',           'HSLuvLinear');
    setappdata(T.hFig2AxesTuneImage,    'HueTempolate',     []);
    setappdata(T.hFig2AxesTuneImage,    'HueColorMap',      []);
    setappdata(T.hFig2AxesTuneImage,    'HueAxesH',         T.hFig2AxesTuneFakeHue);    
	setappdata(T.hFig2AxesTuneImage,    'SatParaRange', [   0   0   0   1   1   1;
                                                            1   1   0   0   1   1;
                                                            0   0.6 0   0   0.6 0]);
	setappdata(T.hFig2AxesTuneImage,    'SatParaOrder',     1);
	setappdata(T.hFig2AxesTuneImage,    'SatValSync',       0);
	setappdata(T.hFig2AxesTuneImage,    'SatGroundOut',     1);
	setappdata(T.hFig2AxesTuneImage,	'SatGroundTime',	0);
	setappdata(T.hFig2AxesTuneImage,    'SatStimTime',      S.TrlDurStim);
	setappdata(T.hFig2AxesTuneImage,    'ValLimRange',  0.00025*2.^(0:0.5:4));
	setappdata(T.hFig2AxesTuneImage,    'ValLimOrder',  4); 
            
    XinRanAnalysis2_Sweep_ScaleBar(T.hFig2SpecScaleBarVal); 
    
    %% Save
%     save([Xin.T.filename(1:end-4) '_P2.mat'], 'R', '-v7.3');
return;

        