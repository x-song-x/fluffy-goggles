function XinRanAnalysis2_Sweep_ScaleBar(varargin)

if nargin==0                % call from GUI
    H =         gcbo;
else
    H =         varargin{1};
end

%% Get Data
ImageH =        getappdata(H,       'ImageH');
RawHue =        getappdata(ImageH,	'RawHue');
RawSat =        getappdata(ImageH,	'RawSat');
RawVal =        getappdata(ImageH,	'RawVal');
LimValRange =   getappdata(ImageH,	'LimValRange');
LimValOrder =   getappdata(ImageH,	'LimValOrder');
    
%% What is changing
switch get(H, 'Tag')
    case 'ScaleBarHue'   
    case 'ScaleBarSat' 
    case 'ScaleBarVal'
        LimValOrder = LimValOrder + 1;
        if LimValOrder> length(LimValRange)
            LimValOrder = 1;
        end
        LimVal =    LimValRange(LimValOrder);
        setappdata(ImageH,	'LimValOrder',  LimValOrder);
        setappdata(ImageH,	'LimVal',       LimVal);
        ylabel(H,	['0                                                             ',...
                    sprintf('%5.3f %%',LimVal*100)],...
                    'FontSize', 8);
    otherwise
end

%% Calculate and Update image

    PtOne_Hue =             min(max(RawHue, 0), 1);
% if contains(lower(S.SesSoundFile),  'sinusoidcycle')
%     R.HueLim =         1.0;
% else
    LimHue =                0.8;
% end 
    PtOne_Hue =             PtOne_Hue * LimHue;
                            % CONTINUOUS or DIScontinous hue  
    
%     R.PtOne_Saturation(R.PtOne_Hue>(1+0.6/S.TrlDurStim)) = 0;
%     R.PtOne_Saturation(R.PtOne_Hue<(0-0.6/S.TrlDurStim)) = 0;
    PtOne_Sat =             RawSat;
    PtOne_Sat(RawHue>1) =	0;
    PtOne_Sat(RawHue<0) =	0;
                            % limit the hue range as 0-HueLim  
                            % and according pixels' sat to be 0;

% % Construct the entire image       
% R.SaturationLim =       0.005;
% R.PtOne_Saturation =	min(R.PtOne_Saturation/R.SaturationLim,1);


    % HSV
%     PtOne_Sat =           min(RawSat/ValLim,1);
    PtOne_Val =             min(RawVal/LimVal,1);
    PtThree_TuneMap =       hsv2rgb([	PtOne_Hue,...
                                        PtOne_Sat,...
                                        PtOne_Val]);
                            
    % HSLuv                        
%     PtOne_Hue =         350*RawHue;
%     PtOne_Saturation =	min(RawSat/ValLim,1)*100;
%     PtOne_Value =       min(RawVal/ValLim,1)*60;
%     PtThree_TuneMap =   zeros(length(PtOne_Hue), 3);
%     for i = 1:length(RawHue)
%         PtThree_TuneMap(i,1:3) = cell2mat(cell(py.hsluv.hsluv_to_rgb([...
%                     PtOne_Hue(i), PtOne_Saturation(i), PtOne_Value(i)])));
%     end                            
                            
                            
% PhPwThree_TuneMap =  reshape(PtThree_TuneMap, size(ImageCData,1), size(ImageCData,2),3);
PhPwThree_TuneMap =  reshape(PtThree_TuneMap, 75, 120, 3);
set(ImageH,...
                'CData',        PhPwThree_TuneMap);

% update Colorbar
% caxis(PseudoH, [0 ValLim]);
