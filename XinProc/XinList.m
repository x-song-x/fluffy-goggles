 %% Xintrinsic File Listing
%   The defination of "dir" function has been changed in Matlab R2018a inte
%   comparing to R2015a

%% Locate The Parent Folder
function XinList
clear all
global F  
%% %%%%%%%%%%%%%%%%%%%%% System Configurations
F.OptConfigVarName =    {...
    'DisplayString',...
    'OptionCharacter',...
    'OptionParameter1',...
    'OptionParameter2'}; 
F.OptConfigTable = cell2table( cell(0,length(F.OptConfigVarName)),...
        'VariableNames',        F.OptConfigVarName);
F.OptConfigTable = [F.OptConfigTable; table(...
        {'Listing Only, patched'},              {'L'},  {'P'},   {''}, 'VariableNames', F.OptConfigVarName)];     
F.OptConfigTable = [F.OptConfigTable; table(...
        {'Listing Only, all'},                  {'L'},  {'A'},   {''}, 'VariableNames', F.OptConfigVarName)];   
F.OptConfigTable = [F.OptConfigTable; table(...
{'Preprocessing, Thorlabs, 5 fps, 3x3 binning'}, {'P'}, {'90x144@5fps'},    {[5 3]},    'VariableNames', F.OptConfigVarName)]; 
F.OptConfigTable = [F.OptConfigTable; table(...
{'Preprocessing, Thorlabs, 5 fps, 1x1 binning'}, {'P'}, {'270x432@5fps'},   {[5 1]},    'VariableNames', F.OptConfigVarName)]; 
F.OptConfigTable = [F.OptConfigTable; table(...
{'Preprocessing, Thorlabs, 20 fps, 3x3 binning'},{'P'}, {'90x144@20fps'},   {[20 3]},   'VariableNames', F.OptConfigVarName)];
F.OptConfigTable = [F.OptConfigTable; table(...
{'Preprocessing, Thorlabs, 20 fps, 1x1 binning'},{'P'}, {'270x432@20fps'},  {[20 1]},   'VariableNames', F.OptConfigVarName)];
F.OptConfigTable = [F.OptConfigTable; table(...
{'Preprocessing, FLIR, 5 fps, 4x4 binning'},     {'P'}, {'75x120@5fps'},    {[5 4]},    'VariableNames', F.OptConfigVarName)]; 
F.OptConfigTable = [F.OptConfigTable; table(...
{'Preprocessing, FLIR, 5 fps, 1x1 binning'},     {'P'}, {'300x480@5fps'},   {[5 1]},    'VariableNames', F.OptConfigVarName)]; 
F.OptConfigTable = [F.OptConfigTable; table(...
{'Plotting (Sweep), FLIR, 5 fps, 4x4 binning'},  {'S'}, {'75x120@5fps'},    {[]},    'VariableNames', F.OptConfigVarName)]; 
F.OptConfigTable = [F.OptConfigTable; table(...
{'Plotting (Sweep), FLIR, 5 fps, 1x1 binning'},  {'S'}, {'300x480@5fps'},   {[]},    'VariableNames', F.OptConfigVarName)]; 
% F.Opt = {'L'};     % Listing
% F.Opt = {'P','75x120@5fps'};            % Listing & Preprocessing           w/ XinPr
% F.Opt = {'P','75x120@5fps'};            % Listing & Preprocessing           w/ XinPr
% F.Opt = {'S','75x120@5fps', ''}; 	% Listing & Ploting                 w/ XinRanAnalysis2_Sweep
% F.Opt = {'S','300x480@5fps', ''};	% Listing & Ploting                 w/ XinRanAnalysis2_Sweep
% F.Opt = {'S','300x480@5fps','_3.7s'};	% Listing & Ploting                 w/ XinRanAnalysis2_Sweep
% F.Opt = {'B','75x120@5fps', ''};	% Listing & Preprocessing & Ploting	w/ both above
% F.Opt = {'B','90x144@5fps', ''};	% Listing & Preprocessing & Ploting	w/ both above
% F.Opt = {'B','300x480@5fps', ''};	% Listing & Preprocessing & Ploting	w/ both above

%% %%%%%%%%%%%%%%%%%%%%% GUI
% F.UI.hFig1 =        figure;
% F.UI.hPanelOpt =    uipanel(F.UI.hFig1, 'Title', 'Select from the following listing options' );
[F.UI.ListIdx, F.UI.ListTF] =  listdlg(...
                    'ListString',       F.OptConfigTable.DisplayString,...
                	'SelectionMode',    'single',...
                    'ListSize',         [350 180],...
                    'InitialValue',     1,...
                    'Name',             'XinList: XINTRINSIC Listing',...
                    'PromptString',     'Select from the following listing options');
if F.UI.ListTF == 0  % cancelled in the GUI
    clear F;
    clear global;
	return;
end
F.Opt{1} = F.OptConfigTable.OptionCharacter{    F.UI.ListIdx};
F.Opt{2} = F.OptConfigTable.OptionParameter1{   F.UI.ListIdx};
F.Opt{3} = F.OptConfigTable.OptionParameter2{   F.UI.ListIdx};

F.DirectoryFull = uigetdir(...
    'D:\=XINTRINSIC=\',... 
    'Pick a parent directory');
%     'X:\',... 

disp(['Xintrinsic Listing for the folder "' F.DirectoryFull '", ' ...
    F.OptConfigTable.DisplayString{F.UI.ListIdx}]);
%                         fprintf('\n');
CurText =   'ExpFolder\tSesRec\tRepTtl\tAddAtts\tSesSound\n';    
                        fprintf(CurText);
% Subfolder Listing
    DirectoryFull = F.DirectoryFull;
    [DirList, DirH, DirText] = Listing(DirectoryFull);  
        F.DirList =         DirList;
        F.DirH =            DirH;
        F.DirText =         DirText;
        F.DirectoryFull =   DirectoryFull;
% Write to File
F.SummaryReportFileH = fopen([...
    F.DirectoryFull, '\', 'DirReport@', datestr(now,'yymmdd'), '.txt'], 'w');
    fprintf(    F.SummaryReportFileH,   [CurText,   F.DirText]);
    fclose(     F.SummaryReportFileH);
%% Listing Function
function [DirList, DirH, DirText] = Listing(DirectoryFull)
    global F S Tm
    DirList =   dir(DirectoryFull);
    DirH =      [];
    DirText =   [];
    for i=1:length(DirList)
        if DirList(i).isdir
            % folder
            switch DirList(i).name
                case '.'
                case '..'
                otherwise
                    CurText = [DirList(i).name '\n'];
                        fprintf(CurText);   DirText = [DirText CurText];
                    DirH(i,1).DirectoryFull = [DirList(i).folder '\' DirList(i).name];
                    [DirH(i,1).DirList, DirH(i,1).DirH, DirH(i,1).DirText] = Listing(DirH(i,1).DirectoryFull);
                    CurText = DirH(i,1).DirText;
                                            DirText = [DirText CurText];
            end
        else
            % file 
            if DirList(i).name(end-3:end) == '.rec'                
                %%%% Here is the host for list recording seesion info %%%%
                F.Sloaded = 0;
                try
                    RecFileName = DirList(i).name(1:end-4);
                    % See if "missingframes"
                    if contains(RecFileName, 'missingframes')
                        if F.Opt{1}=='L' && F.Opt{2}=='A'
                        else
                            continue;   
                        end
                    else
                        CurText = ['\t',   DirList(i).name];
                            fprintf(CurText);   DirText = [DirText CurText];
                    end
                    % See if .mat can be loaded
                    Tm.CurMatFileStr = [DirList(i).folder '\', DirList(i).name(1:end-4), '.mat'];
                    if ~isfile(Tm.CurMatFileStr)
                        fprintf('\n');
                        continue
                    else
                        Tm.RecFileH = whos('-file', Tm.CurMatFileStr);
                        if strcmp(Tm.RecFileH(1).name, 'S') % 'S' struct saved in .mat (pre 220727)
                            RecFileS =  load(Tm.CurMatFileStr);
                            RecFileS =  RecFileS.S;
                        else                                % 'S' fields saved in .mat (post 220727)
                            RecFileS =  load(Tm.CurMatFileStr,  'SesCycleNumTotal', ...
                                                                'AddAtts',...
                                                                'SesSoundFile');
                        end
                    end
                    F.Sloaded = 1;
                    % SesCycleNumTotal or SesCycleTotal
                    if isfield(RecFileS, 'SesCycleNumTotal')                   
                        CurText = [...
                            '\t',   num2str(RecFileS.SesCycleNumTotal)];
                    else
                        CurText = [...
                            '\t',   num2str(RecFileS.SesCycleTotal)];
                    end
                            fprintf(CurText);   DirText = [DirText CurText]; 
                    % AddAtts or 0
                    if isfield(RecFileS, 'AddAtts')          
                        CurText = [...
                            '\t',   num2str(RecFileS.AddAtts)];
                    else
                        CurText = [...
                            '\t',   num2str(0)];
                    end
                            fprintf(CurText);   DirText = [DirText CurText]; 
                    % SesSoundFIle
                        CurText = [...
                            '\t',   RecFileS.SesSoundFile];     
                            fprintf(CurText);   DirText = [DirText CurText];  
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                
                    
                    %%%% Here down is the host for customization code	%%%%%%
    %                 try
                    switch F.Opt{1}
                        case 'L'
                        case 'P'
                            if ~isfile([DirectoryFull, '\', RecFileName, '_', F.Opt{2}, '_P1.mat'])
                                XinRanProc21([DirectoryFull, '\', RecFileName '.rec'], F.Opt{3}(1), F.Opt{3}(2) );
                                pause(2);
                                drawnow;
                            end
                        case 'S'
                            if ~isfile([DirectoryFull, '\', RecFileName, '_', F.Opt{2}, F.Opt{3}, 'Sweep.fig'])
                                XinRanAnalysis2_Sweep([DirectoryFull, '\', RecFileName '_', F.Opt{2}, '_P1.mat']);
                                pause(2);
                                close(gcf);
                                drawnow;
                            end
                        case 'B'
                            if ~isfile([DirectoryFull, '\', RecFileName, '_', F.Opt{2}, '_P1.mat'])
                                XinRanProc2([DirectoryFull, '\', RecFileName '.rec']);
                                pause(2);
%                                 close(gcf);
                                drawnow;
                            end
                            if ~isfile([DirectoryFull, '\', RecFileName, '_', F.Opt{2}, F.Opt{3}, '_Sweep.fig'])
                                XinRanAnalysis2_Sweep([DirectoryFull, '\', RecFileName '_', F.Opt{2}, '_P1.mat']);
                                pause(2);
%                                 close(gcf);
                                drawnow;
                            end
                        otherwise
                    end
                    CurText = [...
                        '\t',   ''];     
                        fprintf(CurText);   DirText = [DirText CurText];
                catch
                    if F.Sloaded
                    CurText = [...
                        '\t',   'function cannot be executed'];     
                        fprintf(CurText);   DirText = [DirText CurText];
                    end
                end
                %%%% Here up is the host for customization code     %%%%%%
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
                    CurText = '\n';
                        fprintf(CurText);   DirText = [DirText CurText];  
            end
        end
    end
    return;

