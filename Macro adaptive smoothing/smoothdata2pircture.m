% %% 计算数据集划分
% % 计算总共有多少行数据
% total_rows = size(result, 1);
% 
% % 计算需要将数据集分成多少份
% num_batches = ceil(total_rows / 501);
% % 计算需要补齐的行数
% remaining_rows = 501 * num_batches - total_rows;
% 
% % 如果有需要补齐的行数，进行补齐操作
% if remaining_rows > 0
%     numRows = size(result, 1);
%     numCols = size(result, 2);
%     targetNumRows = 2004;
%     result = [result; NaN(targetNumRows - numRows, numCols)];
%     total_rows = size(result, 1);
% end
% % 计算需要将数据集分成多少份
% num_batches = ceil(total_rows / 501);
% % 将数据集分成若干份，每份包含501行
% data_batches = cell(1, num_batches);
% for i = 1:num_batches
%     start_row = (i-1)*501 + 1;
%     end_row = min(i*501, total_rows);
%     batch = result(start_row : end_row, :);
%     data_batches{i} = batch;
% end
% result11=data_batches;
% %% 计算行数划分
% % 计算总共有多少行数据
% total_rows = size(unique_x, 1);
% 
% % 计算需要将数据集分成多少份
% num_batches = ceil(total_rows / 501);
% 
% % 计算需要补齐的行数
% remaining_rows = 501 * num_batches - total_rows;
% % 如果有需要补齐的行数，进行补齐操作
% if remaining_rows > 0
%     lastElement = unique_x(end, end);
%     padding(1,1)=lastElement;
%     for i=2:remaining_rows
%         padding(i,:)=padding(i-1, :) + 1;
%     end
%     unique_x = [unique_x; padding];
%     total_rows = size(unique_x, 1);
% end
% % 计算需要将数据集分成多少份
% num_batches = ceil(total_rows / 501);
% % 将数据集分成若干份，每份包含501行
% data_batches = cell(1, num_batches);
% for i = 1:num_batches
%     start_row = (i-1)*501 + 1;
%     end_row = min(i*501, total_rows);
%     batch = unique_x(start_row : end_row, :);
%     data_batches{i} = batch;
% end
% unique_x11=data_batches;
%% 进行同一纬度的绘图
% for i = 1:num_batches
figure;
h=imagesc(unique_t,unique_x, result2);
c = jet;
c = flipud(c);
colormap(c); % 使用彩虹色地图显示速度值
colorbar; % 添加颜色条
% 将值为零的点替换为NaN
result(result2 == 0) = NaN;
set(h,'alphadata',~isnan(result2))
xlabel('时间/s');
ylabel('空间/m');
title({'1车道0方向时空速度分布图'});
 set(gca, 'YDir', 'normal');
% 06是magic，07是ngsim
[result22_1006_new]=smootheddata1_acc(unique_x2_1006,unique_t2_1006,result22_1006 );
% [result22_1007_new]=smootheddata1_acc(unique_x2_1007,unique_t2_1007,result22_1007 );
% [result12_1007_new]=smootheddata1_acc(unique_x1_1007,unique_t1_1007,result12_1007 );
% [result21_1007_new]=smootheddata1(unique_x2_1007,unique_t2_1007,result21_1007);
% [result11_1007_new]=smootheddata1(unique_x1_1007,unique_t1_1007,result11_1007);


[result12_1006_new]=smootheddata1_acc(unique_x1_1006,unique_t1_1006,result12_1006 );
[result21_1006_new]=smootheddata1(unique_x2_1006,unique_t2_1006,result21_1006);
[result11_1006_new]=smootheddata1(unique_x1_1006,unique_t1_1006,result11_1006);
%绘制时空速度分布图
figure;
h=imagesc(unique_t1_1006, unique_x, result_new);
c = jet;
c = flipud(c);
colormap(c); % 使用彩虹色地图显示速度值
colorbar; % 添加颜色条
% 将值为零的点替换为NaN
result_new(result_new == 0) = NaN;
set(h,'alphadata',~isnan(result_new))
xlabel('时间/s');
ylabel('空间/m');
title('1车道0方向时空速度平滑图');
set(gca, 'YDir', 'normal'); % 将 Y 轴方向调整为从下到上
% % 设置 y 轴的范围为 [0, 1400]  
%ylim([0, 800]);
% end
%% 稀疏20%
o=1;
result1=result2;
while o < size(result1,1)
    result1((o:o+50),:)=0;
    o=o+55;
end
figure;
h=imagesc(unique_t, unique_x, result1);
c = jet;
c = flipud(c);
colormap(c); % 使用彩虹色地图显示速度值
colorbar; % 添加颜色条
% 将值为零的点替换为NaN
result1(result1 == 0) = NaN;
set(h,'alphadata',~isnan(result1))
xlabel('时间');
ylabel('空间');
title({'2车道0方向时空速度分布图'},{'数据稀疏度20%'});

[result_new2]=smootheddata1(unique_x2,unique_t2,result);

smoothed= smoothdata(result21_1006_new,"movmean",70);
figure;
h=imagesc(unique_t2_1006, unique_x2_1006, (result21_1006_new));
c = jet;
c = flipud(c);
colormap(c); % 使用彩虹色地图显示速度值
colorbar; % 添加颜色条
% 将值为零的点替换为NaN
result21_1006_new((result21_1006_new == 0)) = NaN;
set(h,'alphadata',~isnan((result21_1006_new)))
xlabel('时间/s');
ylabel('空间/m');
% title({'2车道0方向时空车速平滑图'},{'数据稀疏度20%'});
set(gca, 'YDir', 'normal'); % 将 Y 轴方向调整为从下到上
% set(gca, 'XTick', [], 'YTick', []);  % 隐藏刻度线
% set(gca, 'XLabel', [], 'YLabel', []);  % 隐藏坐标轴标签
% h=imagesc(unique_t, unique_x, result_new1);
% c = jet;
% c = flipud(c);
% colormap(c); % 使用彩虹色地图显示速度值
% colorbar; % 添加颜色条
% % 将值为零的点替换为NaN
% result_new1(result_new1 == 0) = NaN;
% set(h,'alphadata',~isnan(result_new1))
% xlabel('时间');
% ylabel('空间');
% title({'1车道0方向时空车速平滑图'},{'数据稀疏度20%'});
%% 稀疏85%
o=1;
result2=result;
while o <= size(result2,1)
    result2((o:o+10),:)=0;
    o=o+12;
end
figure;
h=imagesc(unique_t, unique_x, result2);
c = jet;
c = flipud(c);
colormap(c); % 使用彩虹色地图显示速度值
colorbar; % 添加颜色条
% 将值为零的点替换为NaN
result2(result2 == 0) = NaN;
set(h,'alphadata',~isnan(result2))
xlabel('时间/s');
ylabel('空间/m');
title({'2车道0方向时空速度分布图'},{'数据稀疏度15%'});

[result_new3]=smootheddata1(unique_x,unique_t,result2);

smoothed= smoothdata(result_new3,"movmean",70);
figure;
h=imagesc(unique_t, unique_x, smoothed);
c = jet;
c = flipud(c);
colormap(c); % 使用彩虹色地图显示速度值
colorbar; % 添加颜色条
% 将值为零的点替换为NaN
smoothed(smoothed == 0) = NaN;
set(h,'alphadata',~isnan(smoothed))
xlabel('时间/s');
ylabel('空间/m');
title({'2车道0方向时空车速平滑图'},{'数据稀疏度50%'});
%% 稀疏度50%
o=1;
result3=resulta;
while o <= size(result3,1)
    result3((o:o+40),:)=0;
    o=o+42;
end
result3(result3 <= -10) = 0;

figure;
h=imagesc(unique_t, unique_x, result3);
c = jet;
c = flipud(c);
colormap(c); % 使用彩虹色地图显示速度值
colorbar; % 添加颜色条
% 将值为零的点替换为NaN
result3(result3 == 0) = NaN;
set(h,'alphadata',~isnan(result3))
xlabel('时间/s');
ylabel('空间/m');
title({'1车道1方向时空速度分布图'},{'数据稀疏度5%'});

[result_new3]=smootheddata1(unique_x,unique_t,result3);
figure
h = imagesc(unique_t, unique_x, result_new3);

% 设置自适应的彩色映射
c = jet;         % 使用彩虹色地图
c = flipud(c);   % 上下翻转颜色映射
colormap(c);     % 应用彩色映射

% 将值为零的点替换为 NaN
result_new3(result_new3 == 0) = NaN;
set(h, 'alphadata', ~isnan(result_new3)); % 使零值透明

% 添加颜色条并设置自适应范围
colorbar; 
clim([-5,5]); % 自适应颜色条范围

% 设置图形标题和坐标轴标签
xlabel('时间/s');
ylabel('空间/m');
title({'1车道1方向时空车速平滑图', '数据稀疏度5%'});

% smoothed= smoothdata(result_new3,"movmean",70);
% figure;
% h=imagesc(unique_t, unique_x, smoothed);
% c = jet;
% c = flipud(c);
% colormap(c); % 使用彩虹色地图显示速度值
% colorbar; % 添加颜色条
% % 将值为零的点替换为NaN
% smoothed(smoothed == 0) = NaN;
% set(h,'alphadata',~isnan(smoothed))
% xlabel('时间');
% ylabel('空间');
% title({'2车道0方向时空车速平滑图'},{'数据稀疏度50%'});
%% 稀疏5%
o=1;
result4=result;
while o <= size(result4,1)
    result4((o:o+40),:)=0;
    o=o+42;
end
figure;
h=imagesc(unique_t, unique_x, result4);
c = jet;
c = flipud(c);
colormap(c); % 使用彩虹色地图显示速度值
colorbar; % 添加颜色条
% 将值为零的点替换为NaN
result4(result4 == 0) = NaN;
set(h,'alphadata',~isnan(result4))
xlabel('时间/s');
ylabel('空间/m');
title({'1车道1方向时空速度分布图'},{'数据稀疏度5%'});

[result_new4]=smootheddata1(unique_x,unique_t,result4);
figure;
h=imagesc(unique_t, unique_x, result_new4);
c = jet;
c = flipud(c);
colormap(c); % 使用彩虹色地图显示速度值
colorbar; % 添加颜色条
% 将值为零的点替换为NaN
result_new4(result_new4 == 0) = NaN;
set(h,'alphadata',~isnan(result_new4))
xlabel('时间/s');
ylabel('空间/m');
title({'1车道1方向时空车速平滑图'},{'数据稀疏度5%'});
set(gca, 'YDir', 'normal'); % 将 Y 轴方向调整为从下到上
smoothed= smoothdata(result_new4,"movmean",70);
figure;
h=imagesc(unique_t, unique_x, smoothed);
c = jet;
c = flipud(c);
colormap(c); % 使用彩虹色地图显示速度值
colorbar; % 添加颜色条
% 将值为零的点替换为NaN
smoothed(smoothed == 0) = NaN;
set(h,'alphadata',~isnan(smoothed))
xlabel('时间');
ylabel('空间');
title({'2车道0方向时空车速平滑图'},{'数据稀疏度30%'});