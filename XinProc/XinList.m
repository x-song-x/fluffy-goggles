 %% Xintrinsic File Listing
% not available for Matlab R2015a
% available for Matlab R2018a
% due to the denifition change on the "dir" function.

%% Locate The Parent Folder
function XinList
clear all
global F
F.DirectoryFull = uigetdir(...
    'Z:\',... 
    'Pick a parent directory');

disp(['Xintrinsic Listing for the folder " ' ...
    F.DirectoryFull ' "']);
                        fprintf('\n');
CurText =   'ExpFolder\tSesRec\tRepTtl\tAddAtts\tSesSound\n';
                        fprintf(CurText);
% Subfolder Listing
[F.DirList, F.DirH, F.DirText] = Listing(F.DirectoryFull);
% Write to File
F.SummaryReportFileH = fopen([...
    F.DirectoryFull, '\', 'DirReport@', datestr(now,'yymmdd'), '.txt'], 'w');
fprintf(    F.SummaryReportFileH,   [CurText,   F.DirText]);
fclose(     F.SummaryReportFileH);

function [DirList, DirH, DirText] = Listing(DirectoryFull)
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
                RecFileName = DirList(i).name(1:end-4);
                    CurText = ['\t',   DirList(i).name];
                        fprintf(CurText);   DirText = [DirText CurText];
                
                %%%% Here is the host for list recording seesion info %%%%
                RecFileS =  load([DirList(i).folder '\', DirList(i).name(1:end-4), '.mat']);
                % SesCycleNumTotal or SesCycleTotal
                if isfield(RecFileS.S, 'SesCycleNumTotal')                    
                    CurText = [...
                        '\t',   num2str(RecFileS.S.SesCycleNumTotal)];
                else
                    CurText = [...
                        '\t',   num2str(RecFileS.S.SesCycleTotal)];
                end
                        fprintf(CurText);   DirText = [DirText CurText]; 
                % AddAtts or 0
                if isfield(RecFileS.S, 'AddAtts')          
                    CurText = [...
                        '\t',   num2str(RecFileS.S.AddAtts)];
                else
                    CurText = [...
                        '\t',   num2str(0)];
                end
                        fprintf(CurText);   DirText = [DirText CurText]; 
                % SesSoundFIle
                    CurText = [...
                        '\t',   RecFileS.S.SesSoundFile];     
                        fprintf(CurText);   DirText = [DirText CurText];           
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    CurText = '\n';
                        fprintf(CurText);   DirText = [DirText CurText];  
            end
        end
    end
    return;

