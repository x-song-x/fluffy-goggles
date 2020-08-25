function XinRanProc1_FaceTrial_Joiner(varargin)
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

%% DATA BINNING
for i = 1: length(A.FileName)
   
    %% Load 'S'
    A.curfilename = [A.PathName, A.FileName{i}];
    S = load([A.PathName, A.FileName{i}(1:36) '_VisSeq.mat']);  
    P = load( A.curfilename);
    S = S.S;
    P = P.P;
    if i==1
        Sall = S;
        Pall = P;
    else
        Sall.TrlDurTotal =      Sall.TrlDurTotal +      S.TrlDurTotal;
        Sall.SesCycleNumTotal =	Sall.SesCycleNumTotal + S.SesCycleNumTotal;
        Sall.SesDurTotal =      Sall.SesDurTotal +      S.SesDurTotal;  
        Sall.SesTrlOrderMat = [ Sall.SesTrlOrderMat;    S.SesTrlOrderMat];
        Sall.SesTrlOrderVec = [ Sall.SesTrlOrderVec,    S.SesTrlOrderVec];
        Sall.SesTrlOrderSoundVec = [	Sall.SesTrlOrderSoundVec, S.SesTrlOrderSoundVec];
        Pall.ProcFrameNumTotal = 	Pall.ProcFrameNumTotal +    P.ProcFrameNumTotal;
        Pall.RawMeanPixel = [       Pall.RawMeanPixel,          P.RawMeanPixel];
        Pall.RawMeanPower = [       Pall.RawMeanPower,          P.RawMeanPower];
        Pall.ProcMeanPixel = [      Pall.ProcMeanPixel,         P.ProcMeanPixel];
        Pall.ProcMeanPower = [      Pall.ProcMeanPower,         P.ProcMeanPower];
        Pall.ProcDataMat = [        Pall.ProcDataMat;           P.ProcDataMat];
    end
    disp([  'Reading: "', A.FileName{i},  '"']);
end
    P = Pall;
    S = Sall;
    A.combinedname = [A.PathName, datestr(now, 'yymmddTHHMMSS')];
    save([A.combinedname, A.FileName{1}(14:end-7), 'All', A.FileName{1}(end-6:end)], 'P', '-v7.3');  
    save([A.combinedname, A.FileName{1}(14:36), '.mat'], 'S', '-v7.3');   

disp('All files are processed');
return;
