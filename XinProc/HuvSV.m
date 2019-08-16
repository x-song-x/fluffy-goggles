% Generate a colormap HuvSV, which has
%   H(Huv):     matching HSLuv's "Hue" distribution, to have a more 
%               perceptually uniform hue. http://www.hsluv.org/
%   S:          matching HSV's "Saturation"=1, to utilize the max contrast
%               on a RGB display device
%   V:          matching HSV's "Value"=1, to utilize the max contrast
%               on a RGB display device

% a standard colormap has 64 color steps
Hsv{1} =  linspace(0, 360, 64)';                           % circular hue
Hsv{2} =  linspace(0, 330, 64)';                           % linear hue
Hsv{3} = [linspace(0, 330, 32) linspace(330, 0, 32)]';     % reciprocating hue

figure
for i = 1:3
    HSLsv60RGB{i} = zeros(64,3);
    for j = 1:64
        HSLsv60RGB{i}(j,1:3) =  cell2mat(cell(py.hsluv.hsluv_to_rgb([Hsv{i}(j) 100 60])));
    end
    HuvSV{i} =      rgb2hsv(HSLsv60RGB{i});
    HuvSV{i}(:,2) = ones(64,1);
    HuvSV{i}(:,3) = ones(64,1);
    RGB_HuvSV{i} =  hsv2rgb(HuvSV{i});
    
    subplot(1,3,i);
    colormap(RGB_HuvSV{i});
    
end

