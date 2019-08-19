% This code is for demonstrating perceptual hue distribution among
% different color spaces
%   HSV:            The standard HSV
%   HSLuv:          Hue distribution on Sat=100, L=60 @ http://www.hsluv.org/
%   CIELCh:         Using code from https://www.mathworks.com/matlabcentral/fileexchange/28790-colorspace-transformations
%   CIECAM02:       ?
%   CIECAM06-UCS:   ?
%   JzAzBz:         ?

%% Shared Settings
clear H;
H0 =	(0:0.5:359.5)';
Hnum =	length(H0);
S0 =	ones(Hnum,1);
figure;

%% HSV
i = 1;
H{1}.Name =             'HSV';
H{1}.ColormapHSV =      [H0/360 S0 S0];
H{1}.Colormap =         hsv2rgb(H{1}.ColormapHSV);
    
%% HSLuv (CIELuv)
% http://www.hsluv.org/
% Saturation(HSLuv) =   70
% Lightness(HSLuv) =    71.9
i = 2;
H{i}.Name =             'HSLuv @S=70, L=71.9';
H{i}.Colormap1 =        zeros(Hnum,3);
for j = 1:Hnum
    H{i}.Colormap1(j,:) =   cell2mat(cell(py.hsluv.hsluv_to_rgb([H0(j) 70 71.9])));
end
H{i}.Colormap2 =        rgb2hsv(H{i}.Colormap1);
H{i}.Colormap2I =       find(H{i}.Colormap2(:,1)<0.5, 1);
H{i}.ColormapHSV =      H{i}.Colormap2([H{i}.Colormap2I:end 1:(H{i}.Colormap2I-1)],:);
H{i}.Colormap =         hsv2rgb([H{i}.ColormapHSV(:,1) S0 S0]);           

%% CIELCh
% code from https://www.mathworks.com/matlabcentral/fileexchange/28790-colorspace-transformations
% 
i = 3;
H{i}.Name =             'CIELCh @L=50, C=31';
addpath 'D:\User_SONG Xindong\Downloads\colorspace\colorspace'
H{i}.Colormap1 =        colorspace('lch->hsv', [50*S0 31*S0 H0]);
H{i}.Colormap1I =       find(H{i}.Colormap1(:,1)<180, 1);
H{i}.ColormapHSV =      H{i}.Colormap1([H{i}.Colormap1I:end 1:(H{i}.Colormap1I-1)],:);
H{i}.Colormap =         hsv2rgb([H{i}.ColormapHSV(:,1)/360 S0 S0]);

%% Plot the result
mapnum = length(H);
for i = 1:mapnum
    gh.axes(i) = subplot(mapnum,1,i);       axis off;
    colormap(gh.axes(i),            H{i}.Colormap);
    gh.colorbar(i) =                colorbar('SouthOutSide');
    gh.test(i) = ylabel(gh.colorbar(i),     H{i}.Name);
    gh.colorbar(i).Position(4) =    1/2/length(H);
    gh.colorbar(i).Ticks =          [];
end




% a standard colormap has 64 color steps
% Generate a colormap HuvSV, which has
%   H(Huv):     matching HSLuv's "Hue" distribution, to have a more 
%               perceptually uniform hue. http://www.hsluv.org/
%   S:          matching HSV's "Saturation"=1, to utilize the max contrast
%               on a RGB display device
%   V:          matching HSV's "Value"=1, to utilize the max contrast
%               on a RGB display device
% 
% HsvName{1} = 'Uniform Hue (Circular)';
% HsvName{2} = 'Uniform Hue (Linear)';
% HsvName{3} = 'Uniform Hue (Reciprocating)';
% Hsv{2} =  linspace(0, 330, 64)';                           % linear hue
% Hsv{3} = [linspace(0, 330, 32) linspace(330, 0, 32)]';     % reciprocating hue