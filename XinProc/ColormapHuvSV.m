% Generate a colormap HuvSV, which has
%   H(Huv):     matching HSLuv's "Hue" distribution, to have a more 
%               perceptually uniform hue. http://www.hsluv.org/
%   S:          matching HSV's "Saturation"=1, to utilize the max contrast
%               on a RGB display device
%   V:          matching HSV's "Value"=1, to utilize the max contrast
%               on a RGB display device

% a standard colormap has 64 color steps
HsvName{1} = 'Uniform Hue (Circular)';
Hsv{1} =  linspace(0, 360, 64)';                           % circular hue
% HsvName{1} = 'Uniform Hue (Linear)';
% HsvName{1} = 'Uniform Hue (Reciprocating)';
% Hsv{2} =  linspace(0, 330, 64)';                           % linear hue
% Hsv{3} = [linspace(0, 330, 32) linspace(330, 0, 32)]';     % reciprocating hue

figure

    h(1) = subplot(4,1,1);  axis off;
    text(0.5, 0.5, 'HSV')
    colormap(h(1), hsv);
    hc(1) = colorbar('South');
    
for i = 1:1
    HSLsv60RGB{i} = zeros(64,3);
    for j = 1:64
        HSLsv60RGB{i}(j,1:3) =  cell2mat(cell(py.hsluv.hsluv_to_rgb([Hsv{i}(j) 100 60])));
    end
    HSLsv60RGB{i} = max(min(HSLsv60RGB{i}, 1), 0);
    HuvSV{i} =      rgb2hsv(HSLsv60RGB{i});
    HuvSV{i}(:,2) = ones(64,1);
    HuvSV{i}(:,3) = ones(64,1);
    RGB_HuvSV{i} =  hsv2rgb(HuvSV{i});
    
    h(i+1) = subplot(4,1,i+1);  axis off;
    colormap(h(i+1), RGB_HuvSV{i});
    hc(i+1) = colorbar('South');
    
end

for i = 1:2
    hc(i).Position(4) = 0.1;
    hc(i).Ticks =       [];
end

% aa = colorspace('lch->hsv', [60*ones(64,1) 30*ones(64,1) Hsv{1} ]);
% aa = aa([5:end 1:4],:)
% CIELChMap = hsv2rgb([aa(:,1)/360 ones(64,1) ones(64,1)]);
% colormap(h(3), CIELChMap);
    
