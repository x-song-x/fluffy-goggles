function XinRanProc2_SesJoiner(varargin)
% Joining Multiple Sessions together
%   by stacking multiple XinRanProc2 processed "P" and original "S"
%   together

clear global
global Tm P S Pcur Scur
%% Get preprocessed ('*_P?.mat') file
[~, Tm.Sys.pcname] = system('hostname');
if strcmp(Tm.Sys.pcname(1:end-1), 'FANTASIA-425')% recording PC 
        Tm.Sys.folder = 'D:\=XINTRINSIC=\';    
else                                            % NOT recording PC
        Tm.Sys.folder = 'X:\';       
end
% get the files
if nargin ==0
    % Calling from direct running of the function
    Tm.RunningSource =   'D';
    [Tm.FileName, Tm.PathName, Tm.FilterIndex] = uigetfile(...
        [Tm.Sys.folder '*_P?.mat'],...
        'Select the sessions to be joined together',...
        'MultiSelect',              'On');
    if Tm.FilterIndex == 0
        clear A;                    % nothing selected
        return
    end
    if iscell(Tm.FileName) == 0      % single file selected
        warndlg('only a single session selected, no need for joining it')
        return
    end
else
    Tm.RunningSource =   'S';
    % Calling from another script
    [Tm.PathName, Tm.FileName, FileExt] = fileparts(varargin{1});
    Tm.PathName =        [Tm.PathName, '\'];
    Tm.FileName =        {[Tm.FileName, FileExt]};
end
            fprintf('Session joining to start on %d  files\n', length(Tm.FileName));

%% DATA BINNING
for i = 1: length(Tm.FileName)
    % Load 'S'
        Tm.curfileparts =   strsplit(Tm.FileName{i}, '_');
        Tm.curSfilename =   [strjoin(Tm.curfileparts(1:5), '_') '.mat'];
            fprintf('#%02d: load "S" file:%s\n', i, Tm.curSfilename);
        Scur = load([Tm.PathName, Tm.curSfilename]); 
        Scur = Scur.S; 
    % Load 'P'
        Tm.curPfilename = Tm.FileName{i};
            fprintf('     load "P" file:%s\n', Tm.curPfilename);
        Pcur = load([Tm.PathName, Tm.curPfilename]);
        Pcur = Pcur.P;
    % Joining together
    if i==1
        S = Scur;
        S.Sessions_joined = {Tm.curSfilename};
        P = Pcur;
            fprintf('      The sound "%s" for all\n', Scur.SesSoundFile );
            fprintf('      Added Att (%s) for all\n',   sprintf('%g ', Scur.AddAtts) );
    else
        % Check "S"
%         if ~strcmp(Scur.SesSoundFile, S.SesSoundFile)
%             fprintf('      The sound "%s" is not the same one\n', Scur.SesSoundFile );
%             continue
%         end
            
%         if ~isequal(Scur.AddAtts, S.AddAtts) && strcmp(Scur.SesSoundFile, S.SesSoundFile)
%             % AddAtt is not the same, but the sound is the same.
%             fprintf('      The AddAtt (%s) is not the same one\n',...
%                                                         sprintf('%g ', Scur.AddAtts) );
%             continue
%         end
        
        % Check if the same sound
        tFlagJoin = 0;
        if      strcmp(Scur.SesSoundFile, S.SesSoundFile)                  % SesSoundFile the SAME
                        tFlagJoin = 1;
                     fprintf('     The sound "%s" is the SAME. Joined!\n',          Scur.SesSoundFile );
        else                                                                % SesSoundFile DIFFERENT
                    fprintf('      The sound "%s" is not the same one\n',           Scur.SesSoundFile );
            if  size(Scur.TrlNames,1) == size(S.TrlNames,1)                     % TrlNames length the SAME
                    fprintf('      But the TrlNumTotal %d is the same\n',           Scur.TrlNumTotal );
                if prod(strcmp(string(S.TrlNames), string(Scur.TrlNames)))          % TrlNames the SAME
                        tFlagJoin = 1;
                    fprintf('      And the TrlNames are the same\n'	);
                else                                                                % TrlNames DIFFERENT
                    fprintf('      Although the TrlNames are different, still joining? '	);
                    reply = input('Y/N [Y]:','s');
                    if ~isempty(reply)
                        if strcmpi(reply(1), 'y')
                        tFlagJoin = 1;                                                  % Still joining
                        end
                    end                    
                end
            else                                                                % TrlNames length DIFFERENT
                    fprintf('      And the TrlNumTotal %d vs %d is not the same\n', Scur.TrlNumTotal, S.TrlNumTotal );
                    fprintf('      So the session is not joined');
            end
        end 
        if ~tFlagJoin;   continue;       end            
        
        % Joining "S"
        S.Sessions_joined =    [S.Sessions_joined,   {Tm.curSfilename}];
        S.SesDurTotal =         S.SesDurTotal +      Scur.SesDurTotal;  
        S.SesFrameTotal =       S.SesFrameTotal +    Scur.SesFrameTotal;
        S.SesFrameNum =        [S.SesFrameNum;       Scur.SesFrameNum];
        S.SesTimestamps =      [S.SesTimestamps;     Scur.SesTimestamps];
        S.SesTrlOrderSoundVec =[S.SesTrlOrderSoundVec, Scur.SesTrlOrderSoundVec];
        
        % Joining "P"
        P.ProcFrameNumTotal =	P.ProcFrameNumTotal +	Pcur.ProcFrameNumTotal;
        P.RawMeanPixel =       [P.RawMeanPixel,         Pcur.RawMeanPixel];
        P.RawMeanPower =       [P.RawMeanPower,         Pcur.RawMeanPower];
        P.ProcMeanPixel =      [P.ProcMeanPixel,        Pcur.ProcMeanPixel];
        P.ProcMeanPower =      [P.ProcMeanPower,        Pcur.ProcMeanPower];
        
        if S.AddAtts == Scur.AddAtts
            S.SesCycleNumTotal =	S.SesCycleNumTotal + Scur.SesCycleNumTotal;
            S.SesTrlOrderMat =     [S.SesTrlOrderMat;    Scur.SesTrlOrderMat];
            S.SesTrlOrderVec =     [S.SesTrlOrderVec,    Scur.SesTrlOrderVec];
            P.ProcDataMat =        [P.ProcDataMat;      Pcur.ProcDataMat];
        else
            S.AddAtts =            [S.AddAtts           Scur.AddAtts];
            S.AddAttNumTotal =      S.AddAttNumTotal +  Scur.AddAttNumTotal;
            S.TrlIndexSoundNum =   [S.TrlIndexSoundNum  1:size(S.TrlNames,1)];
            S.TrlIndexAddAttNum =  [S.TrlIndexAddAttNum S.AddAttNumTotal(end)*ones(1,size(S.TrlNames,1))];
            S.SesTrlOrderMat =     [S.SesTrlOrderMat,   Scur.SesTrlOrderMat + S.TrlNumTotal];
            S.SesTrlOrderVec =     [S.SesTrlOrderVec,   Scur.SesTrlOrderVec + S.TrlNumTotal];
            S.TrlNumTotal =         S.TrlNumTotal +     Scur.TrlNumTotal;   
            P.ProcDataMat =	cat(2,  P.ProcDataMat,      Pcur.ProcDataMat);         
        end
        
            fprintf('      Session joined\n');
    end
%     disp([  'Reading: "', Tm.FileName{i},  '"']);
end
    Tm.combinedname = [Tm.PathName, 'Joined_', S.Sessions_joined{1}(1:end-4),...
                        '_', datestr(now, 'yymmddTHHMMSS')];
    save([Tm.combinedname, '.mat'], 'S', '-v7.3');  
    save([Tm.combinedname, '_', strjoin(Tm.curfileparts(end-1:end),'_')], 'P', '-v7.3');   

disp('All files are processed');
return;
