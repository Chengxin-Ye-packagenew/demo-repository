% 定义文件路径
file1 = 'D:\image_vsp\data_ngsim_1lane_1direction_nox.csv'; % 替换为文件1路径
file2 = 'D:\image_vsp\data_ngsim_1lane_1direction_0.05_benfangfa_nox.csv';  % 替换为文件2路径

% 定义栅格参数
time_min = 0; 
time_max = 700;
time_step = 10; % 时间步长 10s

space_min = 0; 
space_max = 680; 
space_step = 10; % 空间步长 10m

time_bins = time_min:time_step:time_max; % 时间栅格边界
space_bins = space_min:space_step:space_max; % 空间栅格边界

% 定义高斯平滑参数
sigma = 2; % 高斯滤波器的标准差

function emission_grid = compute_emission_grid(data, time_bins, space_bins)
    % 初始化排放栅格
    emission_grid = zeros(length(time_bins) - 1, length(space_bins) - 1);
    
    for i = 1:height(data)
        % 获取当前记录
        start_time = data.start_time(i);
        end_time = data.end_time(i);
        start_pos = data.start_pos(i);
        end_pos = data.end_pos(i);
        emission = data.emission(i);

        % 确定排放所在的时间和空间栅格范围
        time_start_bin = find(time_bins <= start_time, 1, 'last');
        time_end_bin = find(time_bins > end_time, 1, 'first') - 1;
        space_start_bin = find(space_bins <= start_pos, 1, 'last');
        space_end_bin = find(space_bins > end_pos, 1, 'first') - 1;

        % 遍历影响的所有栅格
        for t_bin = time_start_bin:time_end_bin
            for s_bin = space_start_bin:space_end_bin
                % 计算时间和空间的重叠范围
                t_start = max(time_bins(t_bin), start_time);
                t_end = min(time_bins(t_bin + 1), end_time);
                s_start = max(space_bins(s_bin), start_pos);
                s_end = min(space_bins(s_bin + 1), end_pos);

                % 计算时间和空间的占比
                if t_start < t_end && s_start < s_end
                    % 计算时间占比
                    time_fraction = (t_end - t_start) / (end_time - start_time);

                    % 如果轨迹没有空间上的变化，即start_pos == end_pos
                    if start_pos == end_pos
                        space_fraction = 1;  % 假设车辆停在一个栅格内，空间占比为1
                    else
                        space_fraction = (s_end - s_start) / (end_pos - start_pos);
                    end

                    % 计算时间和空间的总占比
                    fraction = time_fraction * space_fraction;

                    % 将按比例分配的排放量累加到对应栅格
                    emission_grid(t_bin, s_bin) = emission_grid(t_bin, s_bin) + emission * fraction;
                end
            end
        end
    end
end


% 读取文件1
% 读取文件1并过滤112号车辆
data1 = readtable(file1, 'TextType', 'string');
data1.Properties.VariableNames = {'vehicle_id', 'start_time', 'end_time', 'start_pos', 'end_pos', ...
    'start_emission_factor', 'end_emission_factor', 'distance', 'emission'};
% 方式二：使用 ismember 函数（适用于多条件过滤）
% data1 = data1(~ismember(data1.vehicle_id, [112,192,189,415,416,190,411,232,229]), :);
% data1 = data1(~ismember(data1.vehicle_id, [112,232,229]), :);
% % 计算文件1的栅格化排放量
data1.start_pos = data1.start_pos;
data1.end_pos = data1.end_pos;
emission_grid1 = compute_emission_grid(data1, time_bins, space_bins);

% 平滑处理文件1
emission_grid1_smoothed = imgaussfilt(emission_grid1, sigma);

% 读取文件2
data2 = readtable(file2, 'TextType', 'string');
data2.Properties.VariableNames = {'vehicle_id', 'start_time', 'end_time', 'start_pos', 'end_pos', ...
    'start_emission_factor', 'end_emission_factor', 'distance', 'emission'};
% 方式二：使用 ismember 函数（适用于多条件过滤）
% data2 = data2(ismember(data2.vehicle_id, [112,2,30,60,90,142,172,262,292,192,411,232]), :);

% 计算文件2的栅格化排放量
emission_grid2 = compute_emission_grid(data2, time_bins, space_bins);

% 平滑处理文件2
emission_grid2_smoothed = imgaussfilt(emission_grid2, sigma);

% 计算两张图的栅格差值
emission_difference = emission_grid1_smoothed - emission_grid2_smoothed;

% 绘制图像
figure;

subplot(1,2, 1);
% 获取文件1的平滑值范围
color_limits = [min(emission_grid1_smoothed(:)), max(emission_grid1_smoothed(:))];
color_limits2 = [min(emission_grid2_smoothed(:)), max(emission_grid2_smoothed(:))];

% 文件1的平滑图
imagesc(time_bins(1:end-1), space_bins(1:end-1), emission_grid1_smoothed');
colorbar;
caxis(color_limits); % 设置颜色条范围为文件1的平滑值范围
xlabel('Time');
ylabel('Distance');
set(gca, 'XTick', [], 'YTick', []);  % 隐藏刻度线
set(gca, 'XLabel', [], 'YLabel', []);  % 隐藏坐标轴标签
set(gca, 'YDir', 'normal'); % 将 Y 轴方向调整为从下到上

% 创建网格坐标
[X, Y] = meshgrid(time_bins(1:end-1) + time_step/2, space_bins(1:end-1) + space_step/2);

% 方法一：使用surf绘制三维曲面图
figure('Position', [100, 100, 1200, 500]);

% 子图1：文件1的三维曲面图
% subplot(1, 2, 1);
surf(X, Y, emission_grid1_smoothed', 'EdgeColor', 'none');
% title('文件1 - 三维排放曲面图', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('时间 (s)', 'FontSize', 10);
ylabel('距离 (m)', 'FontSize', 10);
% zlabel('排放量', 'FontSize', 10);
colorbar;
grid off;
view(45, 30); % 设置视角
colormap(jet); % 设置颜色映射

% % % 文件2的平滑图
% subplot(1, 2, 2);
% imagesc(time_bins(1:end-1), space_bins(1:end-1), emission_grid2_smoothed');
% colorbar;
% caxis(color_limits); % 设置颜色条范围与文件1一致
% xlabel('Time');
% ylabel('Distance');
% set(gca, 'XTick', [], 'YTick', []);  % 隐藏刻度线
% set(gca, 'XLabel', [], 'YLabel', []);  % 隐藏坐标轴标签\
% set(gca, 'YDir', 'normal'); % 将 Y 轴方向调整为从下到上

% % % 差值图
% subplot(1, 3, 3);
% imagesc(time_bins(1:end-1), space_bins(1:end-1), emission_difference');
% colorbar;
% xlabel('Time');
% ylabel('Distance');
% set(gca, 'XTick', [], 'YTick', []);  % 隐藏刻度线
% set(gca, 'XLabel', [], 'YLabel', []);  % 隐藏坐标轴标签
% set(gca, 'YDir', 'normal'); % 将 Y 轴方向调整为从下到上

%%
% 计算二分类热力图 (阈值为 7e-3)
binary_heatmap1 = (emission_grid1_smoothed(:,:) >= 5e-3); % 数据1：预测热点
binary_heatmap2 = (emission_grid2_adjusted(:,:) >= 5e-3); % 数据2：真实热点（或对比数据）

% 绘制数据1的二分类热力图
figure;
imagesc(time_bins(1:end-1),space_bins(1:end-1),  binary_heatmap1);

colorbar;
colormap('gray');
set(gca, 'YDir', 'normal');
% 绘制数据2的二分类热力图
figure;
imagesc( time_bins(1:end-1),space_bins(1:end-1), binary_heatmap2);

colorbar;

set(gca, 'YDir', 'normal');
% ========= 精度评估 =========
% 交集（预测正确的热点）
intersection = binary_heatmap1 & binary_heatmap2;

% 并集（预测或真实为热点）
union_area = binary_heatmap1 | binary_heatmap2;

% IoU 计算
iou = sum(intersection(:)) / sum(union_area(:));
fprintf('IoU (交并比): %.2f%%\n', iou * 100);

% 真阳性（TP）
true_positive = sum(intersection(:));

% 假阳性（FP）：预测为热点但实际上不是
false_positive = sum(binary_heatmap2(:)) - true_positive;

% 假阴性（FN）：实际是热点但没有预测出来
false_negative = sum(binary_heatmap1(:)) - true_positive;

% 精确率 (Precision)
precision = true_positive / (true_positive + false_positive);

% 召回率 (Recall)
recall = true_positive / (true_positive + false_negative);

% F1 分数
F1_score = 2 * (precision * recall) / (precision + recall);

% 输出评估指标
fprintf('准确率 (Precision): %.2f%%\n', precision * 100);
fprintf('召回率 (Recall): %.2f%%\n', recall * 100);
fprintf('F1 分数: %.2f%%\n', F1_score * 100);

%%
% === 创建叠加可视化图 ===
% 初始化 RGB 图像
[rows, cols] = size(binary_heatmap1);
overlay_img = zeros(rows, cols, 3);  % RGB 图像

% 初始化 RGB 图像
[rows, cols] = size(binary_heatmap1);
overlay_img = zeros(rows, cols, 3);  % RGB 图像

% 区域定义
correct_hotspot  = binary_heatmap1 == 1 & binary_heatmap2 == 1;        % 绿色（正确识别）
false_hotspot    = binary_heatmap1 == 0 & binary_heatmap2 == 1;        % 蓝色（误识别）
real_hotspot     = binary_heatmap1 == 1;                               % 红色（真实热点）

% 先全体设为红色（真实热点）
overlay_img(:,:,1) = real_hotspot; % 红色

% 然后用绿色覆盖正确识别热点
overlay_img(:,:,1) = overlay_img(:,:,1) - correct_hotspot; % 去掉红色
overlay_img(:,:,2) = correct_hotspot;                      % 绿色通道

% 然后用蓝色覆盖误识别热点
overlay_img(:,:,1) = overlay_img(:,:,1) - false_hotspot; % 去掉任何残留红
overlay_img(:,:,3) = false_hotspot;                      % 蓝色通道


% === 图像旋转并翻转 ===
% === 图像旋转并翻转 ===

overlay_img_rotated = rot90(overlay_img, -1);      % 顺时针旋转90度
overlay_img_flipped = fliplr(overlay_img_rotated); % 水平翻转（左右镜像）

% 可视化图像（保持坐标轴不变）
figure;
image(time_bins(1:end-1), space_bins(1:end-1), overlay_img_flipped);
set(gca, 'YDir', 'normal');
% title('排放热点识别叠加图（旋转90度+水平翻转）');
xlabel('Time (s)');
ylabel('Space (m)');
xlim([0, 700]);

% 添加图例
hold on;
plot(NaN,NaN,'sr','MarkerFaceColor','r'); % 真实热点
plot(NaN,NaN,'sg','MarkerFaceColor','g'); % 正确识别
plot(NaN,NaN,'sb','MarkerFaceColor','b'); % 错误识别
legend({'Real hotspot', 'Correct hotspot detection', 'False hotspot detection'});

%%
% Calculate statistics for emission_grid1_smoothed
avg_grid1 = mean(emission_grid1(:));  % Average of all grid cells
total_sum_grid1 = sum(emission_grid1(:));  % Total sum of all grid cells

% Calculate statistics for emission_grid2_smoothed
avg_grid2 = mean(emission_grid2(:));  % Average of all grid cells
total_sum_grid2 = sum(emission_grid2(:));  % Total sum of all grid cells

% Display the results
fprintf('File 1 (smoothed):\n');
fprintf('  Average emission per grid cell: %.4f\n', avg_grid1);
fprintf('  Total emission sum: %.4f\n\n', total_sum_grid1);

fprintf('File 2 (smoothed):\n');
fprintf('  Average emission per grid cell: %.4f\n', avg_grid2);
fprintf('  Total emission sum: %.4f\n', total_sum_grid2);


%%
% 计算百分比绝对误差
percentage_absolute_error = abs((emission_grid1_smoothed - emission_grid2_adjusted) ./ emission_grid1_smoothed) * 100;

% 处理分母为零的情况（将无穷大或NaN值设置为0）
percentage_absolute_error(isinf(percentage_absolute_error) | isnan(percentage_absolute_error)) = 0;

% 获取文件1的平滑值范围
color_limits = [min(emission_grid1_smoothed(:)), max(emission_grid1_smoothed(:))];

% 绘制文件1平滑图和调整后的文件2平滑图
figure;

% 文件1的平滑图
subplot(1, 3, 1);
imagesc(time_bins(1:end-1), space_bins(1:end-1), emission_grid1_smoothed');
colorbar;
xlabel('时间 (s)');
ylabel('空间位置 (m)');
caxis(color_limits); % 设置颜色条范围与文件1一致
title('文件1平滑后的排放量分布');
set(gca, 'YDir', 'normal');

% 调整后的文件2平滑图
subplot(1, 3, 2);
imagesc(time_bins(1:end-1), space_bins(1:end-1), emission_grid2_adjusted');
colorbar;
xlabel('时间 (s)');
ylabel('空间位置 (m)');
caxis(color_limits); % 设置颜色条范围与文件1一致
title('调整后的文件2平滑图');
set(gca, 'YDir', 'normal');

% 绘制百分比绝对误差图
subplot(1, 3, 3);
imagesc(time_bins(1:end-1), space_bins(1:end-1), percentage_absolute_error');
colorbar;
xlabel('时间 (s)');
ylabel('空间位置 (m)');
title('文件1 vs 调整后的文件2百分比绝对误差');
set(gca, 'YDir', 'normal');
%%
% 定义目标区域范围
target_time_range = [4200, 4800]; % 横坐标范围
target_space_range = [100, 600];  % 纵坐标范围

% 找到目标区域的索引
time_indices = find(time_bins >= target_time_range(1) & time_bins < target_time_range(2));
space_indices = find(space_bins >= target_space_range(1) & space_bins < target_space_range(2));

% 提取目标区域的排放数据
target_emission_grid1 = emission_grid1_smoothed(time_indices, space_indices);
target_emission_grid2_adjusted = emission_grid2_adjusted(time_indices, space_indices);
target_percentage_error = percentage_absolute_error(time_indices, space_indices);
% 绘制目标区域的排放分布
figure;

% 文件1的目标区域排放分布
subplot(1, 3, 1);
imagesc(time_bins(time_indices), space_bins(space_indices), target_emission_grid1');
colorbar;
xlabel('时间 (s)');
ylabel('空间位置 (m)');
title('文件1目标区域排放分布');
set(gca, 'YDir', 'normal');

% 调整后的文件2目标区域排放分布
subplot(1, 3, 2);
imagesc(time_bins(time_indices), space_bins(space_indices), target_emission_grid2_adjusted');
colorbar;
xlabel('时间 (s)');
ylabel('空间位置 (m)');
title('调整后的文件2目标区域排放分布');
set(gca, 'YDir', 'normal');

% 目标区域的百分比绝对误差
subplot(1, 3, 3);
imagesc(time_bins(time_indices), space_bins(space_indices), target_percentage_error');
colorbar;
xlabel('时间 (s)');
ylabel('空间位置 (m)');
title('目标区域百分比绝对误差');
set(gca, 'YDir', 'normal');
% 计算目标区域的平均排放量
mean_emission_file1 = mean(target_emission_grid1(:));
mean_emission_file2 = mean(target_emission_grid2_adjusted(:));

% 计算目标区域的最大排放量
max_emission_file1 = max(target_emission_grid1(:));
max_emission_file2 = max(target_emission_grid2_adjusted(:));

% 计算目标区域的百分比误差平均值
mean_percentage_error = mean(target_percentage_error(:));

% 输出结果
fprintf('目标区域文件1平均排放量: %.4f\n', mean_emission_file1);
fprintf('目标区域文件2平均排放量: %.4f\n', mean_emission_file2);
fprintf('目标区域最大排放量（文件1）: %.4f\n', max_emission_file1);
fprintf('目标区域最大排放量（文件2）: %.4f\n', max_emission_file2);
fprintf('目标区域百分比误差平均值: %.4f%%\n', mean_percentage_error);
%%
% 计算百分比绝对误差
percentage_absolute_error = abs((emission_grid1_smoothed - emission_grid2_smoothed) ./ emission_grid1_smoothed) * 100;

% 处理分母为零的情况（将无穷大或NaN值设置为0）
percentage_absolute_error(isinf(percentage_absolute_error) | isnan(percentage_absolute_error)) = 0;

% 获取文件1的平滑值范围
color_limits = [min(emission_grid1_smoothed(:)), max(emission_grid1_smoothed(:))];

% 绘制文件1平滑图和调整后的文件2平滑图
figure;

% 文件1的平滑图
subplot(1, 3, 1);
imagesc(time_bins(1:end-1), space_bins(1:end-1), emission_grid1_smoothed');
colorbar;
xlabel('时间 (s)');
ylabel('空间位置 (m)');
caxis(color_limits); % 设置颜色条范围与文件1一致
title('文件1平滑后的排放量分布');
set(gca, 'YDir', 'normal');

% 调整后的文件2平滑图
subplot(1, 3, 2);
imagesc(time_bins(1:end-1), space_bins(1:end-1), emission_grid2_smoothed');
colorbar;
xlabel('时间 (s)');
ylabel('空间位置 (m)');
caxis(color_limits); % 设置颜色条范围与文件1一致
title('调整后的文件2平滑图');
set(gca, 'YDir', 'normal');

% 绘制百分比绝对误差图
subplot(1, 3, 3);
imagesc(time_bins(1:end-1), space_bins(1:end-1), percentage_absolute_error');
colorbar;
xlabel('时间 (s)');
ylabel('空间位置 (m)');
title('文件1 vs 调整后的文件2百分比绝对误差');
set(gca, 'YDir', 'normal');
%% 读取文件3
file3 = 'F:\image_vsp\vehicle_emission_data_with_factors4.csv'; % 替换为文件3路径
data3 = readtable(file3, 'TextType', 'string');
data3.Properties.VariableNames = {'vehicle_id', 'start_time', 'end_time', 'start_pos', 'end_pos', ...
    'start_emission_factor', 'end_emission_factor', 'distance', 'emission'};

% 计算文件3的栅格化排放量
emission_grid3 = compute_emission_grid(data3, time_bins, space_bins);

% 平滑处理文件3
emission_grid3_smoothed = imgaussfilt(emission_grid3, sigma);

% 计算文件3与文件1的差值
difference_file3_vs_file1 = emission_grid1_smoothed - emission_grid3_smoothed;
% 定义差值较大的阈值
difference_threshold = 1 * 10^-5;

% 找到差值较大的区域
large_difference_indices = abs(difference_file3_vs_file1) > difference_threshold;


% 计算调整后的文件3 vs 调整后的文件2的百分比绝对误差
percentage_absolute_error_file3_vs_file2 = abs((emission_grid3_adjusted - emission_grid2_adjusted) ./ emission_grid2_adjusted) * 100;

% 处理分母为零的情况（将无穷大或NaN值设置为0）
percentage_absolute_error_file3_vs_file2(isinf(percentage_absolute_error_file3_vs_file2) | isnan(percentage_absolute_error_file3_vs_file2)) = 0;

% 计算调整后的文件3 vs 文件1的百分比绝对误差
percentage_absolute_error_file3_vs_file1 = abs((emission_grid3_adjusted - emission_grid1_smoothed) ./ emission_grid1_smoothed) * 100;

% 处理分母为零的情况（将无穷大或NaN值设置为0）
percentage_absolute_error_file3_vs_file1(isinf(percentage_absolute_error_file3_vs_file1) | isnan(percentage_absolute_error_file3_vs_file1)) = 0;

% 获取文件1的平滑值范围
color_limits = [min(emission_grid1_smoothed(:)), max(emission_grid1_smoothed(:))];

% 绘制第一张图：调整后的文件3 vs 调整后的文件2
figure;

% 左侧：调整后的文件3平滑图
subplot(1, 3, 1);
imagesc(time_bins(1:end-1), space_bins(1:end-1), emission_grid3_adjusted');
colorbar;
xlabel('时间 (s)');
ylabel('空间位置 (m)');
caxis(color_limits); % 设置颜色条范围与文件1一致
title('调整后的文件3平滑图');
set(gca, 'YDir', 'normal');

% 中间：调整后的文件2平滑图
subplot(1, 3, 2);
imagesc(time_bins(1:end-1), space_bins(1:end-1), emission_grid2_adjusted');
colorbar;
xlabel('时间 (s)');
ylabel('空间位置 (m)');
caxis(color_limits); % 设置颜色条范围与文件1一致
title('调整后的文件2平滑图');
set(gca, 'YDir', 'normal');

% 右侧：调整后的文件3 vs 调整后的文件2的百分比绝对误差图
subplot(1, 3, 3);
imagesc(time_bins(1:end-1), space_bins(1:end-1), percentage_absolute_error_file3_vs_file2');
colorbar;
xlabel('时间 (s)');
ylabel('空间位置 (m)');
title('调整后的文件3 vs 文件2百分比绝对误差');
set(gca, 'YDir', 'normal');

% 绘制第二张图：调整后的文件3 vs 文件1
figure;

% 左侧：调整后的文件3平滑图
subplot(1, 3, 1);
imagesc(time_bins(1:end-1), space_bins(1:end-1), emission_grid3_adjusted');
colorbar;
xlabel('时间 (s)');
ylabel('空间位置 (m)');
caxis(color_limits); % 设置颜色条范围与文件1一致
title('调整后的文件3平滑图');
set(gca, 'YDir', 'normal');

% 中间：文件1的平滑图
subplot(1, 3, 2);
imagesc(time_bins(1:end-1), space_bins(1:end-1), emission_grid1_smoothed');
colorbar;
xlabel('时间 (s)');
ylabel('空间位置 (m)');
caxis(color_limits); % 设置颜色条范围与文件1一致
title('文件1平滑后的排放量分布');
set(gca, 'YDir', 'normal');

% 右侧：调整后的文件3 vs 文件1的百分比绝对误差图
subplot(1, 3, 3);
imagesc(time_bins(1:end-1), space_bins(1:end-1), percentage_absolute_error_file3_vs_file1');
colorbar;
xlabel('时间 (s)');
ylabel('空间位置 (m)');
title('调整后的文件3 vs 文件1百分比绝对误差');
set(gca, 'YDir', 'normal');