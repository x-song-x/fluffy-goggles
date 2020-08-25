function XinRanAnalysis2_FaceTrial_Joiner(varargin)
% Xintrinsic Randomized Analysis 2, for Face trial joiner
clear global
global A R Pcurses
%% Get preprocessed ('*VisSeq_P1.mat') file
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
        [A.Sys.folder '*VisSeq_P1.mat'],...
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

%% Initialization
Pcurses = load([A.PathName, A.FileName{1}]);
A.NumCses =     2;
A.NumCall =     A.NumCses*size(A.FileName,2);
[A.NumC, A.NumT, A.NumH, A.NumW, A.NumF] =	size(Pcurses.P.ProcDataMat);
A.IdxPre =  1:10;
A.IdxRes =  31:60;
R.snapshot =    zeros(A.NumCall, A.NumT,        A.NumH, A.NumW);
R.trlmean =     zeros(           A.NumT,        A.NumH, A.NumW, A.NumF);
R.trlstd =      zeros(           A.NumT,        A.NumH, A.NumW, A.NumF);

%% DATA collecting
for i = 1:A.NumT
% for i = 1:1
    clear Rtrltemp
    Rtrltemp =  zeros(A.NumCall,                A.NumH, A.NumW, A.NumF);
        disp([  'Getting trial# "', num2str(i),  ' done']);
    for j = 1:length(A.FileName)
        disp([  '  Reading file #', num2str(j), ': "', A.FileName{j},  '"']);
        Pcurses = load([A.PathName, A.FileName{j}]);
        Pcurses = Pcurses.P;
        Rtrltemp( (1:2)+(j-1)*A.NumCses, :, :, :) = -(squeeze(...
            Pcurses.ProcDataMat(:,i,:,:,:)./...
            reshape(    repmat(mean(Pcurses.ProcDataMat(:,i,:,:,A.IdxPre),5),[1 1 1 A.NumF]),...
                A.NumCses, 1, A.NumH, A.NumW, A.NumF) )-1);
        if i == 1
            R.snapshot((1:2)+(j-1)*A.NumCses, :, :, :) = -(squeeze(...
                mean(Pcurses.ProcDataMat(:,:,:,:,A.IdxRes),5)./...
                mean(Pcurses.ProcDataMat(:,:,:,:,A.IdxPre),5) )-1);
        end
    end
    save(   [   A.PathName, datestr(now, 'yymmddTHHMMSS'),...
                A.FileName{1}(14:end-7), '_Trial#', num2str(i),'_R.mat'],...
                'Rtrltemp', '-v7.3'); 
    R.trlmean(i,:,:,:) = mean(Rtrltemp, 1);
    R.trlstd(i,:,:,:) =  std(Rtrltemp, 0, 1);
end
    save(   [   A.PathName, datestr(now, 'yymmddTHHMMSS'),...
                A.FileName{1}(14:end-7), '_all_R.mat'],...
                'R', '-v7.3'); 
disp('All files are processed');

figure
for i =1:8
    subplot(1,8,i);
    imagesc(squeeze(mean(R.snapshot(:,i,:,:),1)));
    caxis(0.5e-2*[-1 1]);
end
return;

% for i = 1: length(A.FileName)
%    
%     %% Load 'S'
% %     A.curfilename = [A.PathName, A.FileName{i}];
% %     S = load([A.PathName, A.FileName{i}(1:36) '_VisSeq.mat']);  
% %     P = load( A.curfilename);
% %     S = S.S;
%     P = P.P;
%     if i==1
%         Sall = S;
%         Pall = P;
%     else
%         Sall.TrlDurTotal =      Sall.TrlDurTotal +      S.TrlDurTotal;
%         Sall.SesCycleNumTotal =	Sall.SesCycleNumTotal + S.SesCycleNumTotal;
%         Sall.SesDurTotal =      Sall.SesDurTotal +      S.SesDurTotal;  
%         Sall.SesTrlOrderMat = [ Sall.SesTrlOrderMat;    S.SesTrlOrderMat];
%         Sall.SesTrlOrderVec = [ Sall.SesTrlOrderVec,    S.SesTrlOrderVec];
%         Sall.SesTrlOrderSoundVec = [	Sall.SesTrlOrderSoundVec, S.SesTrlOrderSoundVec];
%         Pall.ProcFrameNumTotal = 	Pall.ProcFrameNumTotal +    P.ProcFrameNumTotal;
%         Pall.RawMeanPixel = [       Pall.RawMeanPixel,          P.RawMeanPixel];
%         Pall.RawMeanPower = [       Pall.RawMeanPower,          P.RawMeanPower];
%         Pall.ProcMeanPixel = [      Pall.ProcMeanPixel,         P.ProcMeanPixel];
%         Pall.ProcMeanPower = [      Pall.ProcMeanPower,         P.ProcMeanPower];
%         Pall.ProcDataMat = [        Pall.ProcDataMat;           P.ProcDataMat];
%     end
%     disp([  'Reading: "', A.FileName{i},  '"']);
% end
%     P = Pall;
%     S = Sall;
%     A.combinedname = [A.PathName, datestr(now, 'yymmddTHHMMSS')];
%     save([A.combinedname, A.FileName{1}(14:end-7), 'All', A.FileName{1}(end-6:end)], 'P', '-v7.3');  
%     save([A.combinedname, A.FileName{1}(14:36), '.mat'], 'S', '-v7.3');   

