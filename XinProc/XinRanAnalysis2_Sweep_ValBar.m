function XinRanAnalysis2_Sweep_ValBar(varargin)

if nargin==0                % call from GUI
    H =         gcbo;
    ValLim =    getappdata(H, 'ValLim');
    ValLim =    ValLim*sqrt(2);
    if ValLim>0.04
        ValLim = 0.00025;
    end
else
    H =         varargin{1};
    ValLim =    varargin{2};
end

%% Get Data
RawHue =        getappdata(H, 'RawHue');
RawSat =        getappdata(H, 'RawSat');
RawVal =        getappdata(H, 'RawVal');
ImageH =        getappdata(H, 'ImageH');
PseudoH =       getappdata(H, 'PseudoH');
ImageCData =    getappdata(H, 'ImageCData');

% update image
PtOne_Saturation =	min(RawSat/ValLim,1);
PtOne_Value =       min(RawVal/ValLim,1);
PtThree_TuneMap =	hsv2rgb([	RawHue,...
                             	PtOne_Saturation,...
                             	PtOne_Value]);
PhPwThree_TuneMap =  reshape(PtThree_TuneMap, size(ImageCData,1), size(ImageCData,2),3);
set(ImageH,...
                'CData',        PhPwThree_TuneMap);

% update Colorbar
caxis(PseudoH, [0 ValLim]);
set(H,...
                'Ticks',        [0 ValLim],...
                'TickLabels',   {'0', [sprintf('%5.3f%%',ValLim*100)]} );
%% Update Data            
setappdata(H,...
                'ValLim',       ValLim);
            
            
            