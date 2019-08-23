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

HueMapOptions = getappdata(ImageH,	'HueMapOptions');
HueMapOrder =   getappdata(ImageH,	'HueMapOrder');
HueMap =        getappdata(ImageH,	'HueMap');
HueTempolate =	getappdata(ImageH,	'HueTempolate');
HueColorMap =   getappdata(ImageH,	'HueColorMap');
HueAxesH =      getappdata(ImageH,	'HueAxesH');
    
SatParaRange =  getappdata(ImageH,  'SatParaRange');
SatParaOrder =  getappdata(ImageH,  'SatParaOrder');
SatValSync =    getappdata(ImageH,	'SatValSync');
SatGroundOut =  getappdata(ImageH,	'SatGroundOut');
SatGroundTime =	getappdata(ImageH,	'SatGroundTime');
SatStimTime =   getappdata(ImageH,  'SatStimTime');

ValLimRange =   getappdata(ImageH,	'ValLimRange');
ValLimOrder =   getappdata(ImageH,	'ValLimOrder');
ValLim =        getappdata(ImageH,	'ValLim');
    
%% What is changing

switch get(H, 'Tag')
    case 'ScaleBarHue'  
        HueMapOrder =   HueMapOrder + 1;
        if HueMapOrder> length(HueMapOptions)
            HueMapOrder = 1;
        end
        HueMap =        HueMapOptions{HueMapOrder};
        HueTempolate =	HSLuvUniformHue(HueMap);
        HueColorMap =   hsv2rgb([HueTempolate ones(length(HueTempolate),2)]);
        setappdata(ImageH,	'HueMapOrder',      HueMapOrder);
        setappdata(ImageH,	'HueMap',           HueMap);
        setappdata(ImageH,	'HueTempolate',     HueTempolate);
        setappdata(ImageH,	'HueColorMap',      HueColorMap);
        colormap(HueAxesH, HueColorMap);        caxis( [0 1]);   
        ylabel(H,	'\uparrow Onset                                                    Offset \uparrow',...
                    'FontSize',             8,...
                    'VerticalAlignment',    'Cap');    
    case 'ScaleBarSat'
        SatParaOrder =  SatParaOrder + 1;
        if SatParaOrder> length(SatParaRange)
            SatParaOrder = 1;
        end
        SatValSync =    SatParaRange(1, SatParaOrder);
        SatGroundOut =  SatParaRange(2, SatParaOrder);
        SatGroundTime =	SatParaRange(3, SatParaOrder);
        setappdata(ImageH,	'SatParaOrder',     SatParaOrder);
        setappdata(ImageH,	'SatValSync',       SatValSync);
        setappdata(ImageH,  'SatGroundOut',     SatGroundOut);
        setappdata(ImageH,	'SatGroundTime',	SatGroundTime);
        switch sprintf('%d',[SatGroundOut SatValSync]) 
            case '00'; str = '                                                          everything \uparrow';
            case '01'; str = '\rightarrow sync w/ value \leftarrow';
            case '10'; str = ['\uparrow out of stim\pm', sprintf('%3.1fs range', SatGroundTime) '        wihtin the range \uparrow']; 
            case '11'; str = ['\uparrow out of stim\pm', sprintf('%3.1fs range', SatGroundTime) '   \rightarrow sync w/ value \leftarrow   ']; 
            otherwise
        end
        ylabel(H,	str,...
                    'FontSize',             8,...
                    'VerticalAlignment',    'Cap');
    case 'ScaleBarVal'
        ValLimOrder =   ValLimOrder + 1;
        if ValLimOrder> length(ValLimRange)
            ValLimOrder = 1;
        end
        ValLim =        ValLimRange(ValLimOrder);
        setappdata(ImageH,	'ValLimOrder',  ValLimOrder);
        setappdata(ImageH,  'ValLim',       ValLim);
        ylabel(H,	['0                                       (in 2xRMS)   ',...
                    sprintf('%5.3f %%',ValLim*100)],...
                    'FontSize',             8,...
                    'VerticalAlignment',    'Cap');
    otherwise
end


%% Calculate and Update image

% HUE
PtOne_Hue =             min(max(RawHue, 0), 1);
InHueTempolate =        linspace(0, 1, length(HueTempolate))';
PtOne_Hue =             interp1q(InHueTempolate, HueTempolate, PtOne_Hue);
                        
% SATURATION
if SatValSync
    PtOne_Sat =         min(RawVal/ValLim,1);
else
    PtOne_Sat =         RawSat;
end
if SatGroundOut
    PtOne_Sat(RawHue>(1+SatGroundTime/SatStimTime)) =	0;
    PtOne_Sat(RawHue<(0-SatGroundTime/SatStimTime)) =	0;
end


% VALUE
PtOne_Val =             min(RawVal/ValLim,1);
PtThree_TuneMap =       hsv2rgb([	PtOne_Hue,...
                                    PtOne_Sat,...
                                    PtOne_Val]);

PhPwThree_TuneMap =  reshape(PtThree_TuneMap, 75, 120, 3);
set(ImageH,...
                'CData',        PhPwThree_TuneMap);

function OutHueTemplate = HSLuvUniformHue(OutputType)
% this function outputs a hue tempolate based on a specifed OutputType 
%   OutputType:     'HSLuvCircular',    covers hue from RED to RED
%                   'HSLuvLinear',      covers hue from RED to PURPLE
%                   'HSLuvZigZag',      covers hue from Green Cyen to Blue
%                                       and back to Cyan and Green
%   OutHueTemplate:	the hue tempolate with more perceptual uniformity
HueData = HueDataHSLuv;
switch OutputType
    case 'HSLuvCircular';   HueStart = 0;   HueStop = 1;    HueZigZag = 0;
    case 'HSLuvLinear';     HueStart = 0;   HueStop = 11/12;HueZigZag = 0;
    case 'HSLuvZigZag';     HueStart = 1/3; HueStop = 2/3;	HueZigZag = 1;
    otherwise
end
IndexHueStart =         find(HueData>HueStart, 1, 'first');
IndexHueStop =          find(HueData<HueStop, 1, 'last');
OutHueTemplate =        HueData(IndexHueStart:IndexHueStop);
if HueZigZag
    OutHueTemplate =	[OutHueTemplate; flipud(OutHueTemplate)];
end

function OutSeq = HueDataHSLuv
% This function contains data generated by HueDistComparison.m
OutSeq = ...
[   0.0001
    0.0013
    0.0024
    0.0036
    0.0047
    0.0058
    0.0069
    0.0080
    0.0091
    0.0102
    0.0112
    0.0123
    0.0133
    0.0144
    0.0154
    0.0164
    0.0175
    0.0185
    0.0195
    0.0205
    0.0215
    0.0225
    0.0234
    0.0244
    0.0254
    0.0264
    0.0273
    0.0283
    0.0292
    0.0302
    0.0311
    0.0320
    0.0330
    0.0339
    0.0348
    0.0357
    0.0366
    0.0375
    0.0384
    0.0393
    0.0402
    0.0411
    0.0420
    0.0429
    0.0438
    0.0447
    0.0456
    0.0464
    0.0473
    0.0482
    0.0490
    0.0499
    0.0508
    0.0516
    0.0525
    0.0533
    0.0542
    0.0550
    0.0559
    0.0567
    0.0576
    0.0584
    0.0593
    0.0601
    0.0610
    0.0618
    0.0627
    0.0635
    0.0643
    0.0652
    0.0660
    0.0668
    0.0677
    0.0685
    0.0694
    0.0702
    0.0710
    0.0719
    0.0727
    0.0735
    0.0744
    0.0752
    0.0760
    0.0769
    0.0777
    0.0786
    0.0794
    0.0802
    0.0811
    0.0819
    0.0828
    0.0836
    0.0845
    0.0853
    0.0862
    0.0870
    0.0879
    0.0888
    0.0896
    0.0905
    0.0914
    0.0922
    0.0931
    0.0940
    0.0949
    0.0957
    0.0966
    0.0975
    0.0984
    0.0993
    0.1002
    0.1011
    0.1021
    0.1030
    0.1039
    0.1048
    0.1058
    0.1067
    0.1077
    0.1086
    0.1096
    0.1105
    0.1115
    0.1125
    0.1135
    0.1145
    0.1155
    0.1165
    0.1175
    0.1186
    0.1196
    0.1207
    0.1217
    0.1228
    0.1239
    0.1250
    0.1261
    0.1272
    0.1284
    0.1295
    0.1307
    0.1318
    0.1330
    0.1342
    0.1355
    0.1367
    0.1380
    0.1392
    0.1405
    0.1419
    0.1432
    0.1446
    0.1459
    0.1473
    0.1488
    0.1502
    0.1517
    0.1532
    0.1547
    0.1563
    0.1579
    0.1595
    0.1612
    0.1629
    0.1646
    0.1664
    0.1682
    0.1700
    0.1718
    0.1736
    0.1754
    0.1772
    0.1790
    0.1808
    0.1827
    0.1845
    0.1863
    0.1882
    0.1900
    0.1919
    0.1937
    0.1956
    0.1975
    0.1994
    0.2013
    0.2032
    0.2051
    0.2070
    0.2090
    0.2109
    0.2129
    0.2149
    0.2168
    0.2189
    0.2209
    0.2229
    0.2250
    0.2270
    0.2291
    0.2312
    0.2333
    0.2355
    0.2377
    0.2398
    0.2420
    0.2443
    0.2465
    0.2488
    0.2511
    0.2534
    0.2557
    0.2581
    0.2605
    0.2630
    0.2654
    0.2679
    0.2704
    0.2730
    0.2756
    0.2782
    0.2808
    0.2835
    0.2862
    0.2890
    0.2918
    0.2946
    0.2975
    0.3005
    0.3034
    0.3065
    0.3095
    0.3126
    0.3158
    0.3190
    0.3223
    0.3256
    0.3290
    0.3325
    0.3359
    0.3393
    0.3426
    0.3459
    0.3490
    0.3521
    0.3551
    0.3581
    0.3610
    0.3638
    0.3666
    0.3693
    0.3720
    0.3746
    0.3771
    0.3796
    0.3821
    0.3845
    0.3869
    0.3892
    0.3915
    0.3937
    0.3959
    0.3981
    0.4002
    0.4023
    0.4043
    0.4063
    0.4083
    0.4103
    0.4122
    0.4141
    0.4159
    0.4177
    0.4195
    0.4213
    0.4230
    0.4247
    0.4264
    0.4281
    0.4297
    0.4313
    0.4329
    0.4345
    0.4360
    0.4375
    0.4390
    0.4405
    0.4420
    0.4434
    0.4448
    0.4462
    0.4476
    0.4489
    0.4502
    0.4516
    0.4529
    0.4541
    0.4554
    0.4566
    0.4579
    0.4591
    0.4603
    0.4614
    0.4626
    0.4638
    0.4649
    0.4660
    0.4671
    0.4682
    0.4693
    0.4703
    0.4714
    0.4724
    0.4734
    0.4744
    0.4754
    0.4764
    0.4773
    0.4783
    0.4792
    0.4801
    0.4810
    0.4819
    0.4828
    0.4837
    0.4845
    0.4854
    0.4862
    0.4870
    0.4878
    0.4886
    0.4894
    0.4902
    0.4909
    0.4917
    0.4924
    0.4931
    0.4939
    0.4946
    0.4952
    0.4959
    0.4966
    0.4972
    0.4978
    0.4984
    0.4990
    0.4996
    0.5001
    0.5007
    0.5013
    0.5018
    0.5023
    0.5029
    0.5034
    0.5039
    0.5045
    0.5050
    0.5055
    0.5060
    0.5065
    0.5070
    0.5075
    0.5080
    0.5085
    0.5090
    0.5094
    0.5099
    0.5104
    0.5108
    0.5113
    0.5118
    0.5122
    0.5127
    0.5131
    0.5136
    0.5140
    0.5144
    0.5149
    0.5153
    0.5157
    0.5162
    0.5166
    0.5170
    0.5174
    0.5179
    0.5183
    0.5187
    0.5191
    0.5195
    0.5199
    0.5203
    0.5207
    0.5211
    0.5215
    0.5219
    0.5223
    0.5227
    0.5231
    0.5235
    0.5238
    0.5242
    0.5246
    0.5250
    0.5254
    0.5258
    0.5261
    0.5265
    0.5269
    0.5273
    0.5276
    0.5280
    0.5284
    0.5288
    0.5291
    0.5295
    0.5299
    0.5303
    0.5306
    0.5310
    0.5314
    0.5317
    0.5321
    0.5326
    0.5333
    0.5340
    0.5347
    0.5354
    0.5362
    0.5370
    0.5377
    0.5385
    0.5392
    0.5399
    0.5406
    0.5413
    0.5420
    0.5427
    0.5434
    0.5441
    0.5448
    0.5455
    0.5462
    0.5469
    0.5476
    0.5484
    0.5491
    0.5498
    0.5505
    0.5512
    0.5519
    0.5526
    0.5533
    0.5541
    0.5548
    0.5555
    0.5563
    0.5570
    0.5577
    0.5585
    0.5592
    0.5600
    0.5608
    0.5615
    0.5623
    0.5631
    0.5639
    0.5647
    0.5654
    0.5662
    0.5671
    0.5679
    0.5687
    0.5695
    0.5703
    0.5712
    0.5720
    0.5729
    0.5738
    0.5746
    0.5755
    0.5764
    0.5773
    0.5782
    0.5791
    0.5800
    0.5810
    0.5819
    0.5829
    0.5838
    0.5848
    0.5858
    0.5868
    0.5878
    0.5888
    0.5899
    0.5909
    0.5920
    0.5930
    0.5941
    0.5952
    0.5964
    0.5975
    0.5986
    0.5998
    0.6010
    0.6022
    0.6034
    0.6046
    0.6059
    0.6072
    0.6085
    0.6098
    0.6111
    0.6125
    0.6139
    0.6153
    0.6167
    0.6181
    0.6196
    0.6211
    0.6227
    0.6242
    0.6258
    0.6275
    0.6291
    0.6308
    0.6326
    0.6343
    0.6361
    0.6380
    0.6399
    0.6418
    0.6438
    0.6458
    0.6478
    0.6500
    0.6521
    0.6544
    0.6566
    0.6590
    0.6614
    0.6638
    0.6664
    0.6690
    0.6715
    0.6741
    0.6766
    0.6792
    0.6817
    0.6843
    0.6868
    0.6893
    0.6919
    0.6944
    0.6969
    0.6994
    0.7019
    0.7044
    0.7069
    0.7094
    0.7119
    0.7144
    0.7169
    0.7194
    0.7219
    0.7244
    0.7269
    0.7294
    0.7319
    0.7345
    0.7370
    0.7395
    0.7420
    0.7445
    0.7470
    0.7496
    0.7521
    0.7547
    0.7572
    0.7598
    0.7623
    0.7649
    0.7675
    0.7701
    0.7726
    0.7753
    0.7779
    0.7805
    0.7831
    0.7858
    0.7884
    0.7911
    0.7938
    0.7965
    0.7992
    0.8019
    0.8047
    0.8075
    0.8102
    0.8130
    0.8159
    0.8187
    0.8215
    0.8244
    0.8273
    0.8302
    0.8332
    0.8361
    0.8390
    0.8417
    0.8444
    0.8471
    0.8496
    0.8521
    0.8546
    0.8570
    0.8593
    0.8616
    0.8639
    0.8661
    0.8682
    0.8703
    0.8724
    0.8744
    0.8764
    0.8783
    0.8802
    0.8821
    0.8839
    0.8858
    0.8875
    0.8893
    0.8910
    0.8927
    0.8944
    0.8960
    0.8977
    0.8993
    0.9008
    0.9024
    0.9039
    0.9054
    0.9069
    0.9084
    0.9099
    0.9113
    0.9127
    0.9141
    0.9155
    0.9169
    0.9183
    0.9196
    0.9209
    0.9223
    0.9236
    0.9249
    0.9262
    0.9274
    0.9287
    0.9299
    0.9312
    0.9324
    0.9337
    0.9349
    0.9361
    0.9373
    0.9385
    0.9397
    0.9408
    0.9420
    0.9432
    0.9443
    0.9455
    0.9466
    0.9478
    0.9489
    0.9501
    0.9512
    0.9523
    0.9534
    0.9546
    0.9557
    0.9568
    0.9579
    0.9590
    0.9601
    0.9612
    0.9623
    0.9634
    0.9645
    0.9656
    0.9667
    0.9678
    0.9689
    0.9700
    0.9711
    0.9722
    0.9733
    0.9744
    0.9755
    0.9766
    0.9777
    0.9788
    0.9799
    0.9810
    0.9821
    0.9832
    0.9843
    0.9854
    0.9865
    0.9876
    0.9887
    0.9899
    0.9910
    0.9921
    0.9933
    0.9944
    0.9955
    0.9967
    0.9978
    0.9990];