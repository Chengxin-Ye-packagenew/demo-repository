% 假设 all_full_trajectories2 和 all_full_trajectories 是两个轨迹数据，包含 [时间, 位置] 列
% all_full_trajectories2 对应 550m 固定点计算重构的轨迹
% all_full_trajectories 对应 50m 固定点计算重构的轨迹

% 假设 unchanging_points 是一个包含车辆 ID 的数组

% 创建融合后的轨迹矩阵
all_fused_trajectories = {};

% 获取轨迹的总数量
num_trajectories = length(all_full_trajectories2);

% 设置时间阈值为 0.5 秒
time_threshold = 1;

% 遍历 unchanging_points 中的每个车辆 ID
for k = 1:length(unchanging_points)
    % 获取当前车辆的 id
    vehicle_id = unchanging_points(k);
    
    % 获取对应的50m和550m轨迹数据
    idx_50m = find(vehiclesInRangeAt50m1.TrajectoryID == vehicle_id);
    idx_550m = find(vehiclesInRangeAt550m1.TrajectoryID == vehicle_id);
    
    % 获取50m和550m轨迹的时间
    time_50m = vehiclesInRangeAt50m1.Time(idx_50m);
    time_550m = vehiclesInRangeAt550m1.Time(idx_550m);
    
    % 获取50m和550m轨迹的数据
    trajectory_down = all_full_trajectories2{k};  % 550m 固定点轨迹
    trajectory_up = all_full_trajectories{k};    % 50m 固定点轨迹
    
    % 获取时间数据
    time_down = trajectory_down(:, 1);
    time_up = trajectory_up(:, 1);
    
    % 计算50m和550m之间的时间差
    time_diff = abs(time_550m - time_50m);
    
    % 创建一个空的矩阵来存储融合后的轨迹
    fused_trajectory = [];
    
    % 当前时间t从50m固定点的时间开始，递增至550m固定点的时间
    t = min(time_down(1,1),time_up(1,1));  % 初始化t为50m固定点的时间
    while time_50m >=t 
         % 获取当前时间对应的轨迹位置
        % 如果t在50m轨迹中存在
        if ismember(t, time_up)
            pos_down = (trajectory_up(time_up == t, 2));  % 50m轨迹的位置
            pos_down = pos_down(1,1);
        else
            % 找到与当前时间最接近的时间点并取位置
            [~, idx] = min(abs(time_up - t));  
            % 如果时间差大于阈值则跳过此点，不进行融合
            if abs(time_up(idx) - t) > time_threshold
                pos_down = NaN;  % 设置为NaN表示该点无法融合
            else
                pos_down = trajectory_up(idx, 2); % 取最接近的点的位置
            end
        end
        fused_position = pos_down;
        % 存储融合后的时间和位置
        fused_trajectory = [fused_trajectory; t, fused_position];
        % 增加时间（每次增加0.04秒）
        t = t + 0.1;
    end
    % 循环，直到t大于或等于550m的时间
    while all(time_50m<=t) && all(t<= time_550m)
        % 计算当前时间t和T
        t_relative = t - time_50m;  % 当前时间与50m时间的差值
        T = time_diff;              % 50m和550m之间的时间差
        
        % 计算时变融合比例 t/T
        t_over_T = t_relative / T;
        ratio_tau_A = t_over_T^3;
        
        % 获取当前时间对应的轨迹位置
        % 如果t在50m轨迹中存在
        if ismember(t, time_down)
            pos_down = trajectory_down(time_down == t, 2);  % 50m轨迹的位置
        else
            % 找到与当前时间最接近的时间点并取位置
            [~, idx] = min(abs(time_down - t));  
            % 如果时间差大于阈值则跳过此点，不进行融合
            if abs(time_down(idx) - t) > time_threshold
                pos_down = NaN;  % 设置为NaN表示该点无法融合
            else
                pos_down = trajectory_down(idx, 2); % 取最接近的点的位置
            end
        end
        
        % 如果t在550m轨迹中存在
        if ismember(t, time_up)
            pos_up = trajectory_up(time_up == t, 2);  % 550m轨迹的位置
        else
            % 找到与当前时间最接近的时间点并取位置
            [~, idx] = min(abs(time_up - t));  
            % 如果时间差大于阈值则跳过此点，不进行融合
            if abs(time_up(idx) - t) > time_threshold
                pos_up = NaN;  % 设置为NaN表示该点无法融合
            else
                pos_up = trajectory_up(idx, 2); % 取最接近的点的位置
            end
        end

        % 如果两个轨迹点都有效（即都没有超过阈值）
        if all(~isnan(pos_down)) && all(~isnan(pos_up))
            % 使用时变融合方程进行融合
            fused_position = ratio_tau_A * pos_down(1,1) + (1 - ratio_tau_A) * pos_up(1,1);
        % elseif ~isnan(pos_down)  % 如果只有50m轨迹点有效
        %     fused_position = pos_down;
        % elseif ~isnan(pos_up)  % 如果只有550m轨迹点有效
        %     fused_position = pos_up;
        else
            fused_position = NaN;  % 如果两个点都无效
           
        end
        
        % 存储融合后的时间和位置
        fused_trajectory = [fused_trajectory; t, fused_position];
        
        % 增加时间（每次增加0.04秒）
        t = t + 0.04;
    end
     time_end = max(time_down(:,1));
    while all(time_550m <= t) && all(t <=time_end)
        % 获取当前时间对应的轨迹位置
        if ismember(t, time_down)
            pos_up = trajectory_down(time_down == t, 2);  % 50m轨迹的位置
        else
            % 找到与当前时间最接近的时间点并取位置
            [~, idx] = min(abs(time_down - t));
            % 如果时间差大于阈值则跳过此点，不进行融合
            if abs(time_down(idx) - t) > time_threshold
                pos_up = NaN;  % 设置为NaN表示该点无法融合
            else
                pos_up = trajectory_down(idx, 2); % 取最接近的点的位置
            end
        end

        % 确保 pos_down 是标量
        if ~isscalar(pos_up)
            pos_up = pos_up(1);  % 取第一个元素，或者根据您的需求调整
        end

        % 只有当 pos_down 是有效数值时才添加到轨迹中
        if ~isnan(pos_up)
            fused_position = pos_up;
            % 存储融合后的时间和位置
            fused_trajectory = [fused_trajectory; t, fused_position];
        end

        % 增加时间（每次增加0.04秒）
        t = t + 0.04;
    end
    % % 扩展原始轨迹数据集  
        extended_input = fused_trajectory(:,1);
    %  以及设定了隐藏层大小和其他训练参数
        hiddenLayerSize = 10;
        trainRatio = 0.90;
        epochs = 50;
        goal = 1e-2;
        learningRate = 0.1;
    %     调用函数进行训练并得到结果
        [bp_net2, validationPerformance] = trainNeuralNetwork(fused_trajectory, hiddenLayerSize, trainRatio, epochs, goal, learningRate);
    % 
    %     使用BP神经网络预测扩展数据集的输出  
        fused_trajectory(:,2) = bp_net2(extended_input')';
    % 存储当前轨迹的融合结果
    all_fused_trajectories{k} = fused_trajectory;
end

% 可视化融合后的轨迹
figure;
hold on;

% 绘制所有融合后的轨迹
for k = 1:num_trajectories
    plot(all_fused_trajectories{k}(:, 1), all_fused_trajectories{k}(:, 2), 'DisplayName', ['Fused Trajectory ' num2str(k)]);
end
% % 绘制这些轨迹点

time_min50 = earliest_50_data1.Time(vehiclesToDraw(1));
time_max50 = earliest_50_data1.Time(vehiclesToDraw(2));
time_min550 = earliest_550_data1.Time(vehiclesToDraw(1));
time_max550 = earliest_550_data1.Time(vehiclesToDraw(2));
% 筛选时间范围内的车辆经过 550m 的轨迹点
vehiclesInRangeAt550m1 = earliest_550_data1(earliest_550_data1.Time >= time_min550 & earliest_550_data1.Time <= time_max550, :);
% 获取筛选后的数据的索引
indicesInOriginalData550m1 = find(earliest_550_data1.Time >= time_min550 & earliest_550_data1.Time <= time_max550);
% 对筛选后的数据按照时间排序
vehiclesInRangeAt550m1 = sortrows(vehiclesInRangeAt550m1, "Time");

% 绘制这些轨迹点
scatter(vehiclesInRangeAt550m1.Time, vehiclesInRangeAt550m1.Distance, 'MarkerFaceColor', [1 0 1], 'Marker', '*');

% 筛选时间范围内的车辆经过 50m 的轨迹点
vehiclesInRangeAt50m1 = earliest_50_data1(earliest_50_data1.Time >= time_min50 & earliest_50_data1.Time <= time_max50, :);
% 获取筛选后的数据的索引
indicesInOriginalData50m1 = find(earliest_50_data1.Time >= time_min50 & earliest_50_data1.Time <= time_max50);
% 对筛选后的数据按照时间排序
vehiclesInRangeAt50m1 = sortrows(vehiclesInRangeAt50m1, "Time");

% 绘制这些轨迹点
scatter(vehiclesInRangeAt50m1.Time, vehiclesInRangeAt50m1.Distance, 'MarkerFaceColor', [1 0 1], 'Marker', '*');
% 设置图形属性
xlabel('Time');
ylabel('Position');
title('Fused Trajectories');
legend;
grid on;
hold off;

% 输出融合后的轨迹
disp('融合后的轨迹：');
disp(all_fused_trajectories);
%%

% 遍历每辆车的轨迹数据
for i = 1:length(all_fused_trajectories_merged)
    % 获取当前车辆的轨迹数据
    trajectory = all_fused_trajectories_merged{i};
    % 遍历每个轨迹点
    for j = 1:size(trajectory, 1)
        % 获取当前轨迹点的时间和位置
        t = trajectory(j, 1);  % 时间
        x = trajectory(j, 2);  % 位置
        % 找到对应时间和位置的索引
        [~, t_idx] = min(abs(unique_t1_1007 - t));  % 找到最接近的时间索引
        [~, x_idx] = min(abs(unique_x1_1007 - x));  % 找到最接近的位置索引

        % 从 smoothed 数据集中获取修正后的速度
        smoothed_speed = result11_1007_new(x_idx, t_idx);
        % 从 smoothed 数据集中获取修正后的速度
        smoothed_acc =  result12_1007_new(x_idx, t_idx);

        % 更新轨迹点的速度
        trajectory(j, 3) = smoothed_speed;
        trajectory(j, 4) = smoothed_acc;
    end
    all_fused_trajectories_merged{i} =  trajectory;

  
end

%% 融合的速度和加速度

% 目标轨迹索引约束设定
target_vehicle_idx = 2; % 提取目标车辆索引 (例如第1辆车)

% 动力学状态矩阵提取机制
% 约束条件：元胞数组中提取的矩阵需包含完整的时空及运动学状态列
target_trajectory = all_fused_trajectories_merged{target_vehicle_idx};

% 解析时间序列与运动学状态向量
t_seq = target_trajectory(:, 1);  % 时间演化序列 t
v_seq = target_trajectory(:, 3);  % 修正后的速度序列 v
a_seq = target_trajectory(:, 4);  % 修正后的加速度序列 a

% 建立可视化反馈回路
figure('Name', '单车轨迹动力学响应特征分析', 'Position', [150, 150, 800, 600]);

% 阶段一：时间-速度响应映射
subplot(2, 1, 1);
plot(t_seq, v_seq, 'LineWidth', 1.5, 'Color', '#0072BD');
title(sprintf('目标车辆 %d 动态演化：时间-速度响应曲线', target_vehicle_idx));
xlabel('时间 (s)');
ylabel('速度 (m/s)');
grid on;
set(gca, 'FontSize', 11, 'LineWidth', 1, 'XMinorGrid', 'on', 'YMinorGrid', 'on');
% 动态自适应坐标轴约束，防止极值点贴边
ylim([min(v_seq)-1, max(v_seq)+1]); 

% 阶段二：时间-加速度响应映射
subplot(2, 1, 2);
plot(t_seq, a_seq, 'LineWidth', 1.5, 'Color', '#D95319');
title(sprintf('目标车辆 %d 动态演化：时间-加速度响应曲线', target_vehicle_idx));
xlabel('时间 (s)');
ylabel('加速度 (m/s^2)');
grid on;
set(gca, 'FontSize', 11, 'LineWidth', 1, 'XMinorGrid', 'on', 'YMinorGrid', 'on');
% 动态自适应坐标轴约束
ylim([min(a_seq)-0.5, max(a_seq)+0.5]);
%% 本轨迹的速度和加速度
% =========================================================================
% 单车轨迹动力学状态平滑重构与响应特征多维映射
% =========================================================================

% 目标轨迹索引约束设定
target_vehicle_idx = 2; % 提取目标车辆索引 

% 动力学状态矩阵提取机制
target_trajectory = all_fused_trajectories_merged{target_vehicle_idx};

% -------------------------------------------------------------------------
% 阶段一：状态张量解析与时域滤波降噪
% -------------------------------------------------------------------------
t_seq = target_trajectory(:, 1);  % 时间演化序列 t
v_seq_raw = target_trajectory(:, 3);  % 原始速度序列 v
a_seq_raw = target_trajectory(:, 4);  % 原始加速度序列 a

% 设定高斯平滑窗口阈值（需根据采样频率与车辆加减速响应周期动态标定，建议取 10-20）
smooth_window = 15; 

% 基于高斯滤波核的动力学状态重构
v_seq_smooth = smoothdata(v_seq_raw, 'gaussian', smooth_window);
a_seq_smooth = smoothdata(a_seq_raw, 'gaussian', 20);

% -------------------------------------------------------------------------
% 阶段二：动力学响应特征图层融合渲染回路
% -------------------------------------------------------------------------
figure('Name', '单车轨迹动力学响应特征解析', 'Position', [150, 150, 800, 650]);

% --- 子系统 1：时间-速度响应映射 ---
subplot(2, 1, 1);
hold on;
% 底层约束：映射原始高频噪声数据（浅色/细线）
plot(t_seq, v_seq_raw, 'Color', [0, 0.4470, 0.7410, 0.3], 'LineWidth', 1.0, ...
    'DisplayName', 'Raw Velocity');
% 表层约束：映射平滑重构后的宏观动力学趋势（深色/粗线）
plot(t_seq, v_seq_smooth, 'Color', '#0072BD', 'LineWidth', 2.0, ...
    'DisplayName', 'Smoothed Velocity');

title(sprintf('目标车辆 %d 动态演化：时间-速度响应特征', target_vehicle_idx), 'FontWeight', 'bold');
xlabel('时间演化 (s)', 'FontWeight', 'bold');
ylabel('速度演化 (m/s)', 'FontWeight', 'bold');
legend('Location', 'best');
grid on; box on;
set(gca, 'FontSize', 11, 'LineWidth', 1.2, 'XMinorGrid', 'on', 'YMinorGrid', 'on', 'TickDir', 'in');

% 动态自适应边界寻优：基于平滑后的极值重构坐标约束，防止极值点贴边
ylim([min(v_seq_smooth)-1, max(v_seq_smooth)+1]); 
hold off;

% --- 子系统 2：时间-加速度响应映射 ---
subplot(2, 1, 2);
hold on;
% 底层约束：映射原始高频噪声数据
plot(t_seq, a_seq_raw, 'Color', [0.8500, 0.3250, 0.0980, 0.3], 'LineWidth', 1.0, ...
    'DisplayName', 'Raw Acceleration');
% 表层约束：映射平滑重构后的宏观动力学趋势
plot(t_seq, a_seq_smooth, 'Color', '#D95319', 'LineWidth', 2.0, ...
    'DisplayName', 'Smoothed Acceleration');

title(sprintf('目标车辆 %d 动态演化：时间-加速度响应特征', target_vehicle_idx), 'FontWeight', 'bold');
xlabel('时间演化 (s)', 'FontWeight', 'bold');
ylabel('加速度演化 (m/s^2)', 'FontWeight', 'bold');
legend('Location', 'best');
grid on; box on;
set(gca, 'FontSize', 11, 'LineWidth', 1.2, 'XMinorGrid', 'on', 'YMinorGrid', 'on', 'TickDir', 'in');

% 物理零值基准线约束（强化加速/减速区间的视觉分割边界）
yline(0, 'k--', 'LineWidth', 1.5, 'HandleVisibility', 'off');

% 动态自适应边界寻优
ylim([min(a_seq_smooth)-1, max(a_seq_smooth)+1]); 
hold off;

%% 真实车辆的速度
% =========================================================================
% 单车真实轨迹动力学状态平滑重构与多尺度特征映射
% =========================================================================

targetIdx = 178; % 标定单一目标车辆提取约束

% 索引边界约束校验与状态空间重构
if targetIdx <= length(trajectory_cell1_ngsim)
    % 轨迹状态矩阵提取机制
    current_trajectory = trajectory_cell1_ngsim{targetIdx};
    
    % -------------------------------------------------------------------------
    % 阶段一：状态张量解析与时域滤波降噪
    % -------------------------------------------------------------------------
    % 采用大括号 {} 提取 table 结构内部的纯数值向量，解除类型约束
    t_real = current_trajectory{:, 2};
    v_real_raw = current_trajectory{:, 4};
    a_real_raw = current_trajectory{:, 5};
    
    % 设定高斯平滑窗口阈值（匹配物理演化周期特性）
    smooth_window = 15; 
    
    % 基于高斯滤波核的动力学状态重构
    v_real_smooth = smoothdata(v_real_raw, 'gaussian', smooth_window);
    a_real_smooth = smoothdata(a_real_raw, 'gaussian', smooth_window);

    % -------------------------------------------------------------------------
    % 阶段二：动力学响应特征双层图谱渲染回路
    % -------------------------------------------------------------------------
    % 构建可视化反馈回路，设定纯白背景适应学术出版
    figure('Name', sprintf('Kinematic State Evolution (ID: %d)', targetIdx), ...
           'Position', [150, 150, 800, 650], 'Color', 'w');
    
    % =========================================================================
    % 子系统 1：时间-速度状态响应映射
    % =========================================================================
    subplot(2, 1, 1);
    hold on;
    
    % 底层微观约束：映射原始真实高频噪声数据（降低 Alpha 透明度弱化权重）
    plot(t_real, v_real_raw, 'Color', [0, 0.4470, 0.7410, 0.3], 'LineWidth', 1.0, ...
        'DisplayName', 'Raw Speed State');
    % 表层宏观约束：映射平滑重构后的演化趋势（强化线宽）
    plot(t_real, v_real_smooth, 'Color', '#0072BD', 'LineWidth', 2.0, ...
        'DisplayName', 'Smoothed Speed Evolution');
    
    % 坐标系物理标量与全局排版约束（全英文，Times New Roman，加粗）
    title('\textbf{Time-Speed State Evolution}', 'Interpreter', 'latex', 'FontSize', 12);
    xlabel('\textbf{Time} $\boldsymbol{t}$ \textbf{(s)}', 'Interpreter', 'latex', 'FontSize', 12);
    ylabel('\textbf{Speed} $\boldsymbol{v}$ \textbf{(m/s)}', 'Interpreter', 'latex', 'FontSize', 12);
    legend('Location', 'best', 'FontName', 'Times New Roman', 'FontSize', 11, 'FontWeight', 'bold');
    
    % 激活高频观测网格与物理边框全面加粗
    grid on; box on;
    set(gca, 'FontName', 'Times New Roman', 'FontSize', 11, 'FontWeight', 'bold', ...
        'LineWidth', 1.2, 'XMinorGrid', 'on', 'YMinorGrid', 'on', 'TickDir', 'in');
    
    % 动态自适应边界寻优
    ylim([min(v_real_smooth)-1, max(v_real_smooth)+1]); 
    hold off;
    
    % =========================================================================
    % 子系统 2：时间-加速度动态响应映射
    % =========================================================================
    subplot(2, 1, 2);
    hold on;
    
    % 底层微观约束：映射原始真实加速度解算噪声
    plot(t_real, a_real_raw, 'Color', [0.8500, 0.3250, 0.0980, 0.3], 'LineWidth', 1.0, ...
        'DisplayName', 'Raw Acceleration Response');
    % 表层宏观约束：映射平滑重构后的加速度趋势
    plot(t_real, a_real_smooth, 'Color', '#D95319', 'LineWidth', 2.0, ...
        'DisplayName', 'Smoothed Acceleration Response');
    
    % 物理基准线约束：零加速度演化分界
    yline(0, 'k--', 'LineWidth', 1.5, 'HandleVisibility', 'off');
    
    % 坐标系物理标量与全局排版约束
    title('\textbf{Time-Acceleration Dynamic Response}', 'Interpreter', 'latex', 'FontSize', 12);
    xlabel('\textbf{Time} $\boldsymbol{t}$ \textbf{(s)}', 'Interpreter', 'latex', 'FontSize', 12);
    ylabel('\textbf{Acceleration} $\boldsymbol{a}$ \textbf{(m/s}$^{\mathbf{2}}$\textbf{)}', 'Interpreter', 'latex', 'FontSize', 12);
    legend('Location', 'best', 'FontName', 'Times New Roman', 'FontSize', 11, 'FontWeight', 'bold');
    
    % 激活高频观测网格与物理边框全面加粗
    grid on; box on;
    set(gca, 'FontName', 'Times New Roman', 'FontSize', 11, 'FontWeight', 'bold', ...
        'LineWidth', 1.2, 'XMinorGrid', 'on', 'YMinorGrid', 'on', 'TickDir', 'in');
    
    % 动态自适应边界寻优
    ylim([min(a_real_smooth)-0.5, max(a_real_smooth)+0.5]); 
    hold off;
    
else
    % 异常处理反馈环
    warning('系统输入异常：目标索引超出底层数据集边界约束。');
end


%% 微观速度和加速度
% =========================================================================
% 多阶动力学演化参量推导与高频噪声平滑重构机制
% =========================================================================

% 目标实体索引及底层状态空间约束设定
target_vehicle_idx = 2; 

% 边界约束校验与状态空间重构
if target_vehicle_idx <= length(all_full_trajectories5)
    % 轨迹状态矩阵提取机制
    target_trajectory = all_full_trajectories5{target_vehicle_idx};
    
    % 解析底层时空序列参量
    t_seq = target_trajectory(:, 1);  % 时间演化序列 t
    x_seq = target_trajectory(:, 2);  % 空间位移序列 x 
    
    % -------------------------------------------------------------------------
    % 阶段一：动力学参量差分推导与时域平滑滤波
    % 机制：中心差分运算会急剧放大离散噪声，需同步介入高斯滤波核准环路
    % -------------------------------------------------------------------------
    delta_t = gradient(t_seq);          % 提取底层时间步长演化约束
    v_seq_raw = gradient(x_seq) ./ delta_t; % 目标实体速度响应参量（含噪声）
    a_seq_raw = gradient(v_seq_raw) ./ delta_t; % 目标实体加速度响应参量（含剧烈噪声）
    
    % 设定高斯平滑窗口阈值
    % 约束：由于二阶微分（加速度）噪声极化更严重，适度扩张平滑窗口以确保曲线收敛
    smooth_window = 20; 
    
    % 动力学状态参量平滑重构
    v_seq_smooth = smoothdata(v_seq_raw, 'gaussian', smooth_window);
    a_seq_smooth = smoothdata(a_seq_raw, 'gaussian', smooth_window);
    
    % -------------------------------------------------------------------------
    % 阶段二：多阶动力学演化双层图谱渲染回路
    % -------------------------------------------------------------------------
    figure('Name', sprintf('Kinematic State Evolution (ID: %d)', target_vehicle_idx), ...
           'Position', [150, 150, 800, 650], 'Color', 'w');
    
    % =========================================================================
    % 子系统 1：时域-速度状态演化映射
    % =========================================================================
    subplot(2, 1, 1);
    hold on;
    
    % 底层约束：映射原始差分推导速度（低权重 Alpha 通道虚化）
    plot(t_seq, v_seq_raw, 'Color', [0, 0.4470, 0.7410, 0.3], 'LineWidth', 1.0, ...
        'DisplayName', 'Raw Derived Speed');
    % 表层约束：映射平滑重构速度演化趋势（高权重实体线）
    plot(t_seq, v_seq_smooth, 'Color', '#0072BD', 'LineWidth', 2.0, ...
        'DisplayName', 'Smoothed Speed Evolution');
    
    % 物理标量与排版张量规范化（全英文，Times New Roman，加粗）
    title('\textbf{Time-Speed State Evolution}', 'Interpreter', 'latex', 'FontSize', 12);
    xlabel('\textbf{Time} $\boldsymbol{t}$ \textbf{(s)}', 'Interpreter', 'latex', 'FontSize', 12);
    ylabel('\textbf{Speed} $\boldsymbol{v}$ \textbf{(m/s)}', 'Interpreter', 'latex', 'FontSize', 12);
    legend('Location', 'best', 'FontName', 'Times New Roman', 'FontSize', 11, 'FontWeight', 'bold');
    
    % 网格约束与坐标系物理边框强化
    grid on; box on;
    set(gca, 'FontName', 'Times New Roman', 'FontSize', 11, 'FontWeight', 'bold', ...
        'LineWidth', 1.2, 'XMinorGrid', 'on', 'YMinorGrid', 'on', 'TickDir', 'in');
    
    % 动态自适应边界寻优
    xlim([min(t_seq), max(t_seq)]);
    ylim([min(v_seq_smooth)-1, max(v_seq_smooth)+1]); % 以平滑曲线极值锚定 y 轴约束
    hold off;
    
    % =========================================================================
    % 子系统 2：时域-加速度动态响应映射
    % =========================================================================
    subplot(2, 1, 2);
    hold on;
    
    % 底层约束：映射原始二阶差分推导加速度
    plot(t_seq, a_seq_raw, 'Color', [0.8500, 0.3250, 0.0980, 0.3], 'LineWidth', 1.0, ...
        'DisplayName', 'Raw Derived Acceleration');
    % 表层约束：映射平滑重构加速度反馈
    plot(t_seq, a_seq_smooth, 'Color', '#D95319', 'LineWidth', 2.0, ...
        'DisplayName', 'Smoothed Acceleration Response');
    
    % 零点动力学分界线锚定（区分驱动/制动域）
    yline(0, 'k--', 'LineWidth', 1.5, 'HandleVisibility', 'off');
    
    % 物理标量与排版张量规范化
    title('\textbf{Time-Acceleration Dynamic Response}', 'Interpreter', 'latex', 'FontSize', 12);
    xlabel('\textbf{Time} $\boldsymbol{t}$ \textbf{(s)}', 'Interpreter', 'latex', 'FontSize', 12);
    ylabel('\textbf{Acceleration} $\boldsymbol{a}$ \textbf{(m/s}$^{\mathbf{2}}$\textbf{)}', 'Interpreter', 'latex', 'FontSize', 12);
    legend('Location', 'best', 'FontName', 'Times New Roman', 'FontSize', 11, 'FontWeight', 'bold');
    
    % 网格约束与坐标系物理边框强化
    grid on; box on;
    set(gca, 'FontName', 'Times New Roman', 'FontSize', 11, 'FontWeight', 'bold', ...
        'LineWidth', 1.2, 'XMinorGrid', 'on', 'YMinorGrid', 'on', 'TickDir', 'in');
    
    % 动态自适应边界寻优
    xlim([min(t_seq), max(t_seq)]);
    ylim([min(a_seq_smooth)-0.5, max(a_seq_smooth)+0.5]);
    hold off;
    
else
    % 异常处理反馈环
    warning('系统输入异常：目标索引超出底层数据集边界约束空间。');
end

%% 宏观速度和加速度
% =========================================================================
% 单车动力学状态时域滤波重构与多尺度特征映射
% =========================================================================

% 目标实体寻址约束
target_id = 218; 

% 引入元胞解包操作约束，提取连续时域下的运动学原始张量
t_data = time_trajectories{target_id};  
v_data_raw = speed_trajectories{target_id};
a_data_raw = acc_trajectories{target_id};

% -------------------------------------------------------------------------
% 阶段一：高斯滤波核准反馈环
% 约束条件：设定滑动窗口尺寸以平衡噪声衰减率与物理极值保真度
% -------------------------------------------------------------------------
smooth_window = 15; % 平滑核窗口参数，可依据采样频率动态调节

% 提取平滑重构后的宏观动力学状态向量
v_data_smooth = smoothdata(v_data_raw, 'gaussian', smooth_window);
a_data_smooth = smoothdata(a_data_raw, 'gaussian', smooth_window);

% -------------------------------------------------------------------------
% 阶段二：多尺度状态响应可视化渲染引擎
% -------------------------------------------------------------------------
figure('Name', sprintf('Kinematic State Evolution of Vehicle %d', target_id), 'Color', 'w', 'Position', [150, 150, 800, 650]);

% --- 映射层级一：时域-速度状态演化 ---
subplot(2, 1, 1);
hold on;
% 底层微观约束：渲染原始离散噪声（采用 RGBA 通道降低 70% 透明度）
plot(t_data, v_data_raw, 'Color', [0, 0, 1, 0.3], 'LineWidth', 1.0, ...
    'DisplayName', 'Raw Speed State');
% 表层宏观约束：渲染平滑重构演化轨迹（标准蓝，线宽强化）
plot(t_data, v_data_smooth, 'b-', 'LineWidth', 2.0, ...
    'DisplayName', 'Smoothed Speed Evolution');

% 坐标系物理标量与全局排版约束
grid on; box on;
set(gca, 'FontSize', 11, 'LineWidth', 1.2, 'XMinorGrid', 'on', 'YMinorGrid', 'on', 'TickDir', 'in');
xlabel('Time / $s$', 'Interpreter', 'latex', 'FontSize', 12);
ylabel('Speed / $km \cdot h^{-1}$', 'Interpreter', 'latex', 'FontSize', 12);
title('\textbf{Time-Speed State Evolution}', 'Interpreter', 'latex', 'FontSize', 12);
legend('Location', 'best', 'Interpreter', 'latex');

% 动态自适应坐标边界寻优（依据速度量纲 km/h 赋予 5 个单位的松弛变量）
ylim([min(v_data_smooth)-5, max(v_data_smooth)+5]);
hold off;

% --- 映射层级二：时域-加速度动态响应 ---
subplot(2, 1, 2);
hold on;
% 底层微观约束：渲染原始解算噪声
plot(t_data, a_data_raw, 'Color', [1, 0, 0, 0.3], 'LineWidth', 1.0, ...
    'DisplayName', 'Raw Acceleration Response');
% 表层宏观约束：渲染平滑重构动力学反馈（标准红，线宽强化）
plot(t_data, a_data_smooth, 'r-', 'LineWidth', 2.0, ...
    'DisplayName', 'Smoothed Acceleration Response');

% 物理坐标系边界条件：零加速度基准线约束（区分牵引/制动状态）
yline(0, 'k--', 'LineWidth', 1.5, 'HandleVisibility', 'off');

% 坐标系物理标量与全局排版约束
grid on; box on;
set(gca, 'FontSize', 11, 'LineWidth', 1.2, 'XMinorGrid', 'on', 'YMinorGrid', 'on', 'TickDir', 'in');
xlabel('Time / $s$', 'Interpreter', 'latex', 'FontSize', 12);
ylabel('Acceleration / $m \cdot s^{-2}$', 'Interpreter', 'latex', 'FontSize', 12);
title('\textbf{Time-Acceleration Dynamic Response}', 'Interpreter', 'latex', 'FontSize', 12);
legend('Location', 'best', 'Interpreter', 'latex');

% 动态自适应坐标边界寻优（依据加速度量纲 m/s^2 赋予 1 个单位的松弛变量）
ylim([min(a_data_smooth)-1, max(a_data_smooth)+1]);
hold off;
%% 融合
% =========================================================================
% Raw Kinematic State Evolution Mapping (No Smoothing, Publication Quality)
% =========================================================================

% 目标轨迹索引约束设定
target_vehicle_idx = 2; 

% 动力学状态矩阵提取机制
target_trajectory = all_fused_trajectories_merged{target_vehicle_idx};

% -------------------------------------------------------------------------
% 阶段一：状态张量解析 (保持原始离散特征，无平滑约束)
% -------------------------------------------------------------------------
t_seq = target_trajectory(:, 1);  % 时间演化序列 t
v_seq = target_trajectory(:, 3);  % 原始提取速度序列 v
a_seq = target_trajectory(:, 4);  % 原始提取加速度序列 a

% 建立可视化反馈回路，设定纯白背景以适应学术出版
figure('Name', sprintf('Raw Kinematic State Evolution (ID: %d)', target_vehicle_idx), ...
       'Position', [150, 150, 800, 650], 'Color', 'w');

% =========================================================================
% 子系统 1：时间-速度状态演化映射
% =========================================================================
subplot(2, 1, 1);
hold on;

% 核心映射：直接渲染原始速度张量 (提升线宽以增强视觉焦点)
plot(t_seq, v_seq, 'LineWidth', 2.0, 'Color', '#D95319', 'DisplayName', 'Raw Speed State');

% 物理标量与全局排版约束 (全英文, Times New Roman, 12pt, 加粗)
title('Time-Speed State Evolution', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Time t (s)', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Speed v (m/s)', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');

% 图例排版约束与外框线宽强化
lgd1 = legend('Location', 'best', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');
set(lgd1, 'LineWidth', 1.5);

% 高频观测网格激活与坐标系(gca)物理边框全面加粗
grid on; box on;
set(gca, 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold', ...
    'LineWidth', 1.5, 'XMinorGrid', 'on', 'YMinorGrid', 'on', 'TickDir', 'in');

% 动态自适应边界寻优，防止极值点贴边
ylim([min(v_seq)-1, max(v_seq)+1]); 
hold off;

% =========================================================================
% 子系统 2：时间-加速度动态响应映射
% =========================================================================
subplot(2, 1, 2);
hold on;

% 核心映射：直接渲染原始加速度张量
plot(t_seq, a_seq, 'LineWidth', 2.0, 'Color', '#D95319', 'DisplayName', 'Raw Acceleration Response');

% 物理坐标系边界条件：零加速度基准线约束（划分驱动/制动拓扑域）
yline(0, 'k--', 'LineWidth', 1.5, 'HandleVisibility', 'off');

% 物理标量与全局排版约束
title('Time-Acceleration Dynamic Response', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Time t (s)', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Acceleration a (m/s^2)', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');

% 图例排版约束
lgd2 = legend('Location', 'best', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');
set(lgd2, 'LineWidth', 1.5);

% 坐标系物理边界与网格强化回路
grid on; box on;
set(gca, 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold', ...
    'LineWidth', 1.5, 'XMinorGrid', 'on', 'YMinorGrid', 'on', 'TickDir', 'in');

% 动态自适应边界寻优
ylim([min(a_seq)-0.5, max(a_seq)+0.5]);
hold off;
%% 宏观
% =========================================================================
% 宏观模型动力学演化独立渲染引擎 (仅平滑曲线，出版级排版)
% =========================================================================

% 目标实体寻址约束
target_id_macro = 218; 

% 引入元胞解包操作约束，提取连续时域下的运动学原始张量
t_data = time_trajectories{target_id_macro};  

% 核心演化机制修正：将宏观模型速度量纲由 km/h 强制转换为 m/s，确保同构物理空间约束
v_data_raw = speed_trajectories{target_id_macro} / 3.6; 
a_data_raw = acc_trajectories{target_id_macro};

% -------------------------------------------------------------------------
% 阶段一：高斯滤波核准反馈环
% -------------------------------------------------------------------------
smooth_window = 15; % 平滑核窗口参数
% 提取平滑重构后的宏观动力学状态向量
v_data_smooth = smoothdata(v_data_raw, 'gaussian', smooth_window);
a_data_smooth = smoothdata(a_data_raw, 'gaussian', smooth_window);

% -------------------------------------------------------------------------
% 阶段二：标准化出版级可视化渲染回路
% -------------------------------------------------------------------------
figure('Name', 'Macroscopic Kinematic State', 'Color', 'w', 'Position', [150, 150, 800, 650]);

% 定义宏观模型专属高对比度色彩张量
color_macro = '#77AC30'; % Apple Green

% =========================================================================
% 子系统 1：时域-速度状态演化映射
% =========================================================================
subplot(2, 1, 1);
hold on;

% 核心约束：直接渲染平滑重构演化轨迹，剔除原始离散噪声图层
plot(t_data, v_data_smooth, 'Color', color_macro, 'LineWidth', 2.5, ...
    'DisplayName', 'Macroscopic Model');

% 物理标量与全局排版约束 (全英文, Times New Roman, 12pt, 加粗)
title('Time-Speed State Evolution', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Time t (s)', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Speed v (m/s)', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');

% 图例排版约束与外框线宽强化
lgd1 = legend('Location', 'best', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');
set(lgd1, 'LineWidth', 1.5);

% 高频观测网格激活与坐标系(gca)物理边框全面加粗
grid on; box on;
set(gca, 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold', ...
    'LineWidth', 1.5, 'XMinorGrid', 'on', 'YMinorGrid', 'on', 'TickDir', 'in');

% 动态自适应坐标边界寻优
ylim([min(v_data_smooth)-1, max(v_data_smooth)+1]);
hold off;

% =========================================================================
% 子系统 2：时域-加速度动态响应映射
% =========================================================================
subplot(2, 1, 2);
hold on;

% 核心约束：直接渲染平滑重构动力学反馈
plot(t_data, a_data_smooth, 'Color', color_macro, 'LineWidth', 2.5, ...
    'DisplayName', 'Macroscopic Model');

% 物理坐标系边界条件：零加速度基准线约束（划分牵引/制动拓扑域）
yline(0, 'k--', 'LineWidth', 1.5, 'HandleVisibility', 'off');

% 物理标量与全局排版约束
title('Time-Acceleration Dynamic Response', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Time t (s)', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Acceleration a (m/s^2)', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');

% 图例排版约束
lgd2 = legend('Location', 'best', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');
set(lgd2, 'LineWidth', 1.5);

% 坐标系物理边界与网格强化回路
grid on; box on;
set(gca, 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold', ...
    'LineWidth', 1.5, 'XMinorGrid', 'on', 'YMinorGrid', 'on', 'TickDir', 'in');

% 动态自适应坐标边界寻优
ylim([min(a_data_smooth)-0.5, max(a_data_smooth)+0.5]);
hold off;
%% 微观
% =========================================================================
% 微观模型动力学演化独立渲染引擎 (仅平滑曲线，出版级排版)
% =========================================================================

% 目标实体寻址约束
target_vehicle_idx = 2; 

% 边界约束校验与状态空间重构
if target_vehicle_idx <= length(all_full_trajectories5)
    % 轨迹状态矩阵提取机制
    target_trajectory = all_full_trajectories5{target_vehicle_idx};
    
    % 解析底层时空序列参量
    t_seq = target_trajectory(:, 1);  
    x_seq = target_trajectory(:, 2);  
    
    % -------------------------------------------------------------------------
    % 阶段一：动力学参量差分推导与时域平滑滤波反馈环
    % 约束：中心差分会急剧放大离散噪声，利用扩张窗口的高斯滤波约束二阶发散
    % -------------------------------------------------------------------------
    delta_t = gradient(t_seq);          
    v_seq_raw = 3.6*gradient(x_seq) ./ delta_t; 
    a_seq_raw = gradient(v_seq_raw) ./ delta_t; 
    
    % 设定高斯平滑窗口阈值
    smooth_window = 20; 
    
    % 提取平滑重构后的微观动力学状态向量
    v_seq_smooth = smoothdata(v_seq_raw, 'gaussian', smooth_window);
    a_seq_smooth = smoothdata(a_seq_raw, 'gaussian', smooth_window);
    
    % -------------------------------------------------------------------------
    % 阶段二：标准化出版级可视化渲染回路
    % -------------------------------------------------------------------------
    figure('Name', 'Microscopic Kinematic State', 'Color', 'w', 'Position', [150, 150, 800, 650]);
    
    % 定义微观模型专属高对比度色彩张量 (皇家紫)
    color_micro = '#7E2F8E'; 
    
    % =========================================================================
    % 子系统 1：时域-速度状态演化映射
    % =========================================================================
    subplot(2, 1, 1);
    hold on;
    
    % 核心约束：直接渲染平滑重构演化轨迹，剔除原始高频噪声图层
    plot(t_seq, v_seq_smooth, 'Color', color_micro, 'LineWidth', 2.5, ...
        'DisplayName', 'Microscopic Model');
    
    % 物理标量与全局排版约束 (全英文, Times New Roman, 12pt, 加粗)
    title('Time-Speed State Evolution', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');
    xlabel('Time t (s)', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Speed v (m/s)', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');
    
    % 图例排版约束与外框线宽强化
    lgd1 = legend('Location', 'best', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');
    set(lgd1, 'LineWidth', 1.5);
    
    % 坐标系(gca)物理边框全面加粗与高频观测网格激活
    grid on; box on;
    set(gca, 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold', ...
        'LineWidth', 1.5, 'XMinorGrid', 'on', 'YMinorGrid', 'on', 'TickDir', 'in');
    
    % 动态自适应坐标边界寻优
    xlim([min(t_seq), max(t_seq)]);
    ylim([min(v_seq_smooth)-1, max(v_seq_smooth)+1]);
    hold off;
    
    % =========================================================================
    % 子系统 2：时域-加速度动态响应映射
    % =========================================================================
    subplot(2, 1, 2);
    hold on;
    
    % 核心约束：直接渲染平滑重构动力学反馈
    plot(t_seq, a_seq_smooth, 'Color', color_micro, 'LineWidth', 2.5, ...
        'DisplayName', 'Microscopic Model');
    
    % 物理坐标系边界条件：零加速度基准线约束（划分牵引/制动拓扑域）
    yline(0, 'k--', 'LineWidth', 1.5, 'HandleVisibility', 'off');
    
    % 物理标量与全局排版约束
    title('Time-Acceleration Dynamic Response', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');
    xlabel('Time t (s)', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Acceleration a (m/s^2)', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');
    
    % 图例排版约束
    lgd2 = legend('Location', 'best', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');
    set(lgd2, 'LineWidth', 1.5);
    
    % 坐标系物理边界与网格强化回路
    grid on; box on;
    set(gca, 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold', ...
        'LineWidth', 1.5, 'XMinorGrid', 'on', 'YMinorGrid', 'on', 'TickDir', 'in');
    
    % 动态自适应坐标边界寻优
    xlim([min(t_seq), max(t_seq)]);
    ylim([min(a_seq_smooth)-0.5, max(a_seq_smooth)+0.5]);
    hold off;
    
else
    % 异常防御机制
    warning('System Exception: Target index exceeds boundary constraints.');
end
%% 真实
% =========================================================================
% NGSIM 真实轨迹动力学演化独立渲染引擎 (仅平滑曲线，出版级排版)
% =========================================================================

targetIdx = 178; % 标定单一目标车辆提取约束

% 索引边界约束校验与状态空间重构
if targetIdx <= length(trajectory_cell1_ngsim)
    % 轨迹状态矩阵提取机制
    current_trajectory = trajectory_cell1_ngsim{targetIdx};
    
    % -------------------------------------------------------------------------
    % 阶段一：状态张量解析与时域滤波降噪
    % -------------------------------------------------------------------------
    % 采用大括号 {} 提取 table 结构内部的纯数值向量，解除类型约束
    t_real = current_trajectory{:, 2};
    v_real_raw = current_trajectory{:, 4};
    a_real_raw = current_trajectory{:, 5};
    
    % 设定高斯平滑窗口阈值（匹配物理演化周期特性）
    smooth_window = 15; 
    
    % 提取平滑重构后的宏观动力学状态向量
    v_real_smooth = smoothdata(v_real_raw, 'gaussian', smooth_window);
    a_real_smooth = smoothdata(a_real_raw, 'gaussian', smooth_window);

    % -------------------------------------------------------------------------
    % 阶段二：标准化出版级可视化渲染回路
    % -------------------------------------------------------------------------
    figure('Name', sprintf('NGSIM Ground Truth State (ID: %d)', targetIdx), ...
           'Color', 'w', 'Position', [150, 150, 800, 650]);
           
    % 定义该模型专属高对比度色彩张量 (Deep Blue)
    color_ngsim = '#0072BD'; 
    
    % =========================================================================
    % 子系统 1：时域-速度状态响应映射
    % =========================================================================
    subplot(2, 1, 1);
    hold on;
    
    % 核心约束：直接渲染平滑重构演化轨迹，剔除原始高频噪声图层
    plot(t_real, v_real_smooth, 'Color', color_ngsim, 'LineWidth', 2.5, ...
        'DisplayName', 'NGSIM Ground Truth');
    
    % 物理标量与全局排版约束 (全英文, Times New Roman, 12pt, 加粗)
    title('Time-Speed State Evolution', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');
    xlabel('Time t (s)', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Speed v (m/s)', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');
    
    % 图例排版约束与外框线宽强化
    lgd1 = legend('Location', 'best', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');
    set(lgd1, 'LineWidth', 1.5);
    
    % 坐标系(gca)物理边框全面加粗与高频观测网格激活
    grid on; box on;
    set(gca, 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold', ...
        'LineWidth', 1.5, 'XMinorGrid', 'on', 'YMinorGrid', 'on', 'TickDir', 'in');
    
    % 动态自适应坐标边界寻优
    ylim([min(v_real_smooth)-1, max(v_real_smooth)+1]); 
    hold off;
    
    % =========================================================================
    % 子系统 2：时域-加速度动态响应映射
    % =========================================================================
    subplot(2, 1, 2);
    hold on;
    
    % 核心约束：直接渲染平滑重构动力学反馈
    plot(t_real, a_real_smooth, 'Color', color_ngsim, 'LineWidth', 2.5, ...
        'DisplayName', 'NGSIM Ground Truth');
    
    % 物理坐标系边界条件：零加速度基准线约束（划分牵引/制动拓扑域）
    yline(0, 'k--', 'LineWidth', 1.5, 'HandleVisibility', 'off');
    
    % 物理标量与全局排版约束
    title('Time-Acceleration Dynamic Response', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');
    xlabel('Time t (s)', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Acceleration a (m/s^2)', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');
    
    % 图例排版约束
    lgd2 = legend('Location', 'best', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');
    set(lgd2, 'LineWidth', 1.5);
    
    % 坐标系物理边界与网格强化回路
    grid on; box on;
    set(gca, 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold', ...
        'LineWidth', 1.5, 'XMinorGrid', 'on', 'YMinorGrid', 'on', 'TickDir', 'in');
    
    % 动态自适应坐标边界寻优
    ylim([min(a_real_smooth)-0.5, max(a_real_smooth)+0.5]); 
    hold off;
    
else
    % 异常处理反馈环
    warning('System Exception: Target index exceeds boundary constraints.');
end
%% 本模型
% =========================================================================
% 融合轨迹动力学演化独立渲染引擎 (仅平滑曲线，出版级排版)
% =========================================================================

% 目标轨迹索引约束设定
target_vehicle_idx = 2; 

% 动力学状态矩阵提取机制
target_trajectory = all_fused_trajectories_merged{target_vehicle_idx};

% -------------------------------------------------------------------------
% 阶段一：状态张量解析与时域滤波降噪
% -------------------------------------------------------------------------
t_seq = target_trajectory(:, 1);      % 时间演化序列 t
v_seq_raw = target_trajectory(:, 3);  % 原始速度序列 v
a_seq_raw = target_trajectory(:, 4);  % 原始加速度序列 a

% 设定高斯平滑窗口阈值
smooth_window = 15; 

% 基于高斯滤波核的动力学状态重构
v_seq_smooth = smoothdata(v_seq_raw, 'gaussian', smooth_window);
a_seq_smooth = smoothdata(a_seq_raw, 'gaussian', 20);

% -------------------------------------------------------------------------
% 阶段二：标准化出版级可视化渲染回路
% -------------------------------------------------------------------------
figure('Name', sprintf('Fused Model State (ID: %d)', target_vehicle_idx), ...
       'Color', 'w', 'Position', [150, 150, 800, 650]);

% 定义该模型专属高对比度色彩张量 (Deep Blue)
color_fused = '#A2142F'; 


% =========================================================================
% 子系统 1：时域-速度状态响应映射
% =========================================================================
subplot(2, 1, 1);
hold on;

% 核心约束：直接渲染平滑重构演化轨迹，剔除原始高频噪声图层
plot(t_seq, v_seq_smooth, 'Color', color_fused, 'LineWidth', 2.5, ...
    'DisplayName', 'Fused Model');

% 物理标量与全局排版约束 (全英文, Times New Roman, 12pt, 加粗)
title('Time-Speed State Evolution', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Time t (s)', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Speed v (m/s)', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');

% 图例排版约束与外框线宽强化
lgd1 = legend('Location', 'best', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');
set(lgd1, 'LineWidth', 1.5);

% 坐标系(gca)物理边框全面加粗与高频观测网格激活
grid on; box on;
set(gca, 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold', ...
    'LineWidth', 1.5, 'XMinorGrid', 'on', 'YMinorGrid', 'on', 'TickDir', 'in');

% 动态自适应坐标边界寻优
ylim([min(v_seq_smooth)-1, max(v_seq_smooth)+1]); 
hold off;

% =========================================================================
% 子系统 2：时域-加速度动态响应映射
% =========================================================================
subplot(2, 1, 2);
hold on;

% 核心约束：直接渲染平滑重构动力学反馈
plot(t_seq, a_seq_smooth, 'Color', color_fused, 'LineWidth', 2.5, ...
    'DisplayName', 'Fused Model');

% 物理坐标系边界条件：零加速度基准线约束（划分牵引/制动拓扑域）
yline(0, 'k--', 'LineWidth', 1.5, 'HandleVisibility', 'off');

% 物理标量与全局排版约束
title('Time-Acceleration Dynamic Response', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Time t (s)', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Acceleration a (m/s^2)', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');

% 图例排版约束
lgd2 = legend('Location', 'best', 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold');
set(lgd2, 'LineWidth', 1.5);

% 坐标系物理边界与网格强化回路
grid on; box on;
set(gca, 'FontName', 'Times New Roman', 'FontSize', 12, 'FontWeight', 'bold', ...
    'LineWidth', 1.5, 'XMinorGrid', 'on', 'YMinorGrid', 'on', 'TickDir', 'in');

% 动态自适应坐标边界寻优
ylim([min(a_seq_smooth)-0.5, max(a_seq_smooth)+0.5]); 
hold off;