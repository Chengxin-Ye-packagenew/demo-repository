% % 假设 trajectory505 是一个 table，列名分别为 Time, Distance, Speed, Acceleration
%%
% 预取列为向量（避免表的逐行索引开销）
speed = data_new_all.speed;                  % N×1 double
accel = data_new_all.tan_acc;             % N×1 double

absSpeed  = abs(speed);
absAccel  = abs(accel);
N = numel(speed);

% 用整数标签表示状态，0=unknown
% 1=cruise, 2=rapid_decel, 3=rapid_accel, 4=slow_accel, 5=full_decel
state = zeros(N,1,'uint8');

% 为了保持 if/elseif 的“优先级”，按顺序逐类覆盖“尚未赋值”的样本
rem = state==0;

% 1) 巡航（最高优先级）
mask = absSpeed < 5;
idx = rem & mask;
state(idx) = 1;  rem(idx) = false;

% 2) 急减速
mask = accel < -5 & absSpeed < 100 & absAccel < 10;
idx = rem & mask;
state(idx) = 2;  rem(idx) = false;

% 3) 急加速
mask = accel > 5  & absSpeed < 100 & absAccel < 10;
idx = rem & mask;
state(idx) = 3;  rem(idx) = false;

% 4) 慢加速
mask = accel >= 0 & accel <= 5& absSpeed < 100;
idx = rem & mask;
state(idx) = 4;  rem(idx) = false;

% 5) 满减速（其实是“缓减速”？按你原逻辑保留）
mask = accel > -5 & accel < 0 & absSpeed < 100;
idx = rem & mask;
state(idx) = 5;  rem(idx) = false;

% 一次性切片，避免循环内拼接
cruise_state                 = data_new_all(state==1, :);
rapid_deceleration_state     = data_new_all(state==2, :);
rapid_acceleration_state     = data_new_all(state==3, :);
slow_acceleration_state      = data_new_all(state==4, :);
full_deceleration_state      = data_new_all(state==5, :);
unknown_state                = data_new_all(state==0, :);

% [m, n] = size(data_new_all);
% 
% % 初始化六个状态对应的矩阵
% cruise_state = [];  % 巡航状态
% rapid_deceleration_state = [];  % 急减速状态
% rapid_acceleration_state = [];  % 急加速状态
% slow_acceleration_state = [];  % 慢加速
% full_deceleration_state = [];  % 满减速
% unknown_state = [];  % 未知状态
% 
% for i = 1:m
%     speed = data_new_all.speed(i);  % 访问第七列的速度
%     acceleration = data_new_1lane.tan_acc(i);  % 访问第八列的加速度
% 
%     % 根据交通状态条件划分
%     if abs(speed) < 5
%         cruise_state = [cruise_state; data_new_all(i, :)];  % 巡航状态
%     elseif acceleration < -5 && abs(speed)<100 && abs(acceleration)<10
%         rapid_deceleration_state = [rapid_deceleration_state; data_new_all(i, :)];  % 急减速状态
%     elseif acceleration > 5 && abs(speed)<100 && abs(acceleration)<10
%         rapid_acceleration_state = [rapid_acceleration_state; data_new_all(i, :)];  % 急加速状态
%     elseif acceleration >= 0 && acceleration <= 5 && abs(speed)<100
%         slow_acceleration_state = [slow_acceleration_state; data_new_all(i, :)];  % 慢加速
%     elseif acceleration > -5 && acceleration < 0 && abs(speed)<100
%         full_deceleration_state = [full_deceleration_state; data_new_all(i, :)];  % 满减速
%     else
%         unknown_state = [unknown_state; data_new_all(i, :)];  % 未知状态
%     end
% end
% 
% % 输出每个状态的矩阵
% disp('巡航状态数据:');
% disp(cruise_state);
% disp('急减速状态数据:');
% disp(rapid_deceleration_state);
% disp('急加速状态数据:');
% disp(rapid_acceleration_state);
% disp('慢加速状态数据:');
% disp(slow_acceleration_state);
% disp('满减速状态数据:');
% disp(full_deceleration_state);
% disp('未知状态数据:');
% disp(unknown_state);
% 
% % 如果需要，你可以将每个状态的数据保存到不同的文件中，例如：
% % writetable(cell2table(cruise_state), 'cruise_state.csv');
% % writetable(cell2table(rapid_deceleration_state), 'rapid_deceleration_state.csv');
% % writetable(cell2table(rapid_acceleration_state), 'rapid_acceleration_state.csv');
% % writetable(cell2table(slow_acceleration_state), 'slow_acceleration_state.csv');
% % writetable(cell2table(full_deceleration_state), 'full_deceleration_state.csv');
% % writetable(cell2table(unknown_state), 'unknown_state.csv');

%%
% 定义交通状态
states = {'巡航状态', '急减速状态', '急加速状态', '慢加速', '满减速', '未知状态'};
data_sets = {cruise_state, rapid_deceleration_state, rapid_acceleration_state, ...
    slow_acceleration_state, full_deceleration_state, unknown_state};

% 对每个状态分别绘制包络线
for state_idx = 1:length(states)-1
    % 获取当前状态的数据
    current_data = data_sets{state_idx};
    v_state = current_data.speed;            % 速度
    a_state = current_data.tan_acc;         % 加速度
    
    % 如果该状态下有数据，进行包络线绘制
    if ~isempty(v_state)
        % 创建一个新的图形窗口
        figure;
        
        % 将速度划分为多个区间（bins）
        v_min = min(v_state); % 最小速度
        v_max = max(v_state); % 最大速度
        num_bins = 80;  % 区间数量
        v_edges = linspace(v_min, v_max, num_bins + 1); % 速度区间的边界
        
        % 初始化包络线数据
        v_centers = zeros(1, num_bins); % 每个区间的中心速度
        a_mean = zeros(1, num_bins);    % 每个区间的加速度均值
        a_upper = zeros(1, num_bins);   % 每个区间的加速度 97.5百分位数
        a_lower = zeros(1, num_bins);   % 每个区间的加速度 2.5百分位数
        
        % 计算每个速度区间的加速度统计量
        for i = 1:num_bins
            % 找到当前速度区间的数据点
            idx_bin = (v_state >= v_edges(i)) & (v_state < v_edges(i+1));
            if any(idx_bin)
                % 计算加速度的均值、97.5百分位数和2.5百分位数
                a_mean(i) = mean(a_state(idx_bin));
                a_upper(i) = prctile(a_state(idx_bin), 97.5);
                a_lower(i) = prctile(a_state(idx_bin), 2.5);
                % 计算区间中心速度
                v_centers(i) = (v_edges(i) + v_edges(i+1)) / 2;
            else
                % 如果区间内没有数据点，设为 NaN
                a_mean(i) = NaN;
                a_upper(i) = NaN;
                a_lower(i) = NaN;
                v_centers(i) = (v_edges(i) + v_edges(i+1)) / 2;
            end
        end
        
        % 去除 NaN 值
        valid_idx = ~isnan(a_mean) & ~isnan(a_upper) & ~isnan(a_lower);
        v_centers = v_centers(valid_idx);
        a_mean = a_mean(valid_idx);
        a_upper = a_upper(valid_idx);
        a_lower = a_lower(valid_idx);
        
        % 绘制包络线
        hold on;
        plot(v_state, a_state, '.', 'MarkerSize', 5); % 原始数据点
        plot(v_centers, a_mean, 'LineWidth', 2); % 均值
        plot(v_centers, a_upper, 'r--', 'LineWidth', 2); % 上边界（97.5百分位数）
        plot(v_centers, a_lower, 'r--', 'LineWidth', 2); % 下边界（2.5百分位数）
        fill([v_centers, fliplr(v_centers)], [a_upper, fliplr(a_lower)], 'r', 'FaceAlpha', 0.2, 'EdgeColor', 'none'); % 填充区域
        
        % 设置标题和标签
        title([states{state_idx}, '的速度-加速度包络线']);
        xlabel('速度 (单位)');
        ylabel('加速度 (单位)');
        legend('数据点', '均值', '97.5百分位数', '2.5百分位数');
        grid on;
    end
end
%% 不同状态下的不同速度区间内的加速度和下一时刻加速度的分布
% 定义交通状态
states = {'巡航状态','急减速状态','急加速状态','慢加速','满减速','未知状态'};
data_sets = {cruise_state, rapid_deceleration_state, rapid_acceleration_state, ...
    slow_acceleration_state, full_deceleration_state};

% 参数：按“当前加速度”分箱
bin_width = 0.10;  % 例如 0.1，加到需要的粒度
min_pts   = 5;     % 每个箱最少样本数，避免过拟合/拟合失败

% 设定速度区间（根据实际需要调整）
speed_bins = [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100]; % 例如：10km/h为一个区间

for state_idx = 4
    current_data = data_sets{state_idx};
    v_state = current_data.speed;  % 速度数据
    a_state = current_data.tan_acc(:);  % 加速度数据

    if isempty(a_state), continue; end

    % 为 a_t 构建分箱边界（带缓冲避免边界遗漏）
    a_min = min(a_state);
    a_max = max(a_state);
    left  = floor(a_min/bin_width)*bin_width;
    right = ceil(a_max/bin_width)*bin_width;
    a_edges = left:bin_width:right;

    % 遍历每个速度区间
    for speed_idx = 1:numel(speed_bins)-1
        speed_lo = speed_bins(speed_idx);
        speed_hi = speed_bins(speed_idx + 1);

        % 筛选在当前速度区间内的数据
        speed_mask = (v_state >= speed_lo & v_state < speed_hi);
        filtered_a_state = a_state(speed_mask);

        if isempty(filtered_a_state), continue; end

        % 创建新图，单独展示每个速度区间
        figure; hold on; grid on;
        legend_entries = {};

        % 遍历每个“当前加速度”的区间
        for i = 1:numel(a_edges)-1
            lo = a_edges(i);
            hi = a_edges(i+1);

            % 找到满足 lo <= a_t < hi 的时间索引 k
            k = find(filtered_a_state >= lo & filtered_a_state < hi);

            % 只保留有 k+1 不越界的点（才能拿到 a_{t+1}）
            k = k(k < numel(filtered_a_state));

            if numel(k) >= min_pts
                a_next = filtered_a_state(k + 1);   % 对应的下一时刻加速度

                % 用正态分布拟合 a_{t+1} 的条件分布
                try
                    pd = fitdist(a_next, 'Normal');
                catch
                    % 如果极端情况下方差接近0导致失败，跳过该箱
                    continue;
                end

                % 绘制 pdf：x 轴是 a_{t+1}
                x_vals = linspace(min(a_next), max(a_next), 200);
                y_vals = pdf(pd, x_vals);
                plot(x_vals, y_vals, 'LineWidth', 2);

                % 图例用区间中心值表示“当前加速度代表值”
                bin_center = (lo + hi)/2;
                legend_entries{end+1} = sprintf('a_t ≈ %.3f ( [%g, %g) )', bin_center, lo, hi); %#ok<SAGROW>
            end
        end

        % 标题和标签：图中显示当前速度区间的信息
        title(sprintf('%s：速度区间 [%g, %g) km/h 下的 p(a_{t+1} | a_t \in \text{bin}) 的高斯拟合', ...
            states{state_idx}, speed_lo, speed_hi));
        xlabel('a_{t+1}（下一时刻加速度）');
        ylabel('概率密度');

        % 显示图例
        if ~isempty(legend_entries)
            legend(legend_entries, 'Location', 'best');
        else
            legend('off');
            text(0.5, 0.5, '该速度区间下没有满足样本数的分箱', 'Units', 'normalized', 'HorizontalAlignment', 'center');
        end
    end
end
%%
% ===== Define driving states =====
states = {'Cruise','Rapid Deceleration','Rapid Acceleration','Slow Acceleration','Full Deceleration','Unknown'};
data_sets = {cruise_state, rapid_deceleration_state, rapid_acceleration_state, ...
    slow_acceleration_state, full_deceleration_state};

% ===== Parameters =====
bin_width = 0.10;   % Acceleration bin width (e.g. 0.1)
min_pts   = 5;      % Minimum number of samples per bin
speed_bins = [0,10,20,30,40,50,60,70,80,90,100];  % Speed bins in km/h

for state_idx = 4
    current_data = data_sets{state_idx};
    v_state = current_data.speed;        % Speed data
    a_state = current_data.tan_acc(:);   % Acceleration data

    if isempty(a_state), continue; end

    % Build acceleration bin edges
    a_min = min(a_state);
    a_max = max(a_state);
    left  = floor(a_min/bin_width)*bin_width;
    right = ceil(a_max/bin_width)*bin_width;
    a_edges = left:bin_width:right;

    % Iterate through each speed bin
    for speed_idx = 1:numel(speed_bins)-1
        speed_lo = speed_bins(speed_idx);
        speed_hi = speed_bins(speed_idx + 1);

        % Filter data within current speed range
        speed_mask = (v_state >= speed_lo & v_state < speed_hi);
        filtered_a_state = a_state(speed_mask);

        if isempty(filtered_a_state), continue; end

        % Create figure for this speed range
        figure; hold on; grid on;
        legend_entries = {};

        % Iterate through acceleration bins
        for i = 1:numel(a_edges)-1
            lo = a_edges(i);
            hi = a_edges(i+1);

            % Find indices satisfying lo <= a_t < hi
            k = find(filtered_a_state >= lo & filtered_a_state < hi);

            % Keep indices where k+1 is valid
            k = k(k < numel(filtered_a_state));

            if numel(k) >= min_pts
                a_next = filtered_a_state(k + 1);   % Next-step acceleration

                % Fit normal distribution for a_{t+1}
                try
                    pd = fitdist(a_next, 'Normal');
                catch
                    continue;  % Skip if fit fails
                end

                % Compute PDF
                x_vals = linspace(min(a_next), max(a_next), 200);
                y_vals = pdf(pd, x_vals);

                % Bin center (representative a_t)
                bin_center = (lo + hi) / 2;

                % ---- Color selection ----
                % % If current acceleration ≈ 1, draw in red; otherwise gray
                % if abs(bin_center - 1.65) < 0.00001
                %     line_color = [1 0 0];  % Red
                % else
                    line_color = [0.5 0.5 0.5];  % Gray
                % end

                % Plot line
                plot(x_vals, y_vals, 'Color', line_color, 'LineWidth', 2);

                % Legend entry
                legend_entries{end+1} = sprintf('a_t ≈ %.3f ( [%g, %g) )', ...
                    bin_center, lo, hi); %#ok<SAGROW>
            end
        end

        % Titles and labels
        title(sprintf('%s: Speed range [%g, %g) km/h - Gaussian fits of p(a_{t+1} | a_t in bin)', ...
            states{state_idx}, speed_lo, speed_hi));
        xlabel('a_{t+1} (Next-step Acceleration)');
        ylabel('Probability Density');

        % Legend display
        if ~isempty(legend_entries)
            legend(legend_entries, 'Location', 'best');
        else
            legend('off');
            text(0.5, 0.5, 'No bins with sufficient samples in this speed range', ...
                'Units', 'normalized', 'HorizontalAlignment', 'center');
        end

        hold off;
    end
end

%% 联合分布
% 定义交通状态
states = {'巡航状态', '急减速状态', '急加速状态', '慢加速', '满减速', '未知状态'};
data_sets = {cruise_state, rapid_deceleration_state, rapid_acceleration_state, ...
    slow_acceleration_state, full_deceleration_state};

% 参数：按“当前速度”分箱
speed_bin_width = 5;  % 每个速度区间5为单位
min_pts = 5;  % 每个箱最少样本数，避免过拟合/拟合失败

for state_idx = 4
    current_data = data_sets{state_idx};
    v_state = current_data.speed;     % 速度数据
    a_state = current_data.tan_acc(:); % 加速度数据

    if isempty(a_state), continue; end

    % 为 v_state 构建速度分箱边界
    v_min = min(v_state);
    v_max = max(v_state);
    left = floor(v_min / speed_bin_width) * speed_bin_width;
    right = ceil(v_max / speed_bin_width) * speed_bin_width;
    v_edges = left:speed_bin_width:right;

    figure; hold on; grid on;

    legend_entries = {};
    % 遍历每个“当前速度”的区间
    for i = 1:numel(v_edges)-1
        lo_v = v_edges(i);
        hi_v = v_edges(i+1);

        % 筛选出当前速度区间内的加速度数据
        k = find(v_state >= lo_v & v_state < hi_v);

        % 确保有足够的数据用于下一时刻加速度，并且k不越界
        if numel(k) >= min_pts && all(k + 1 <= numel(a_state))  % 确保k+1不会越界
            % 获取该速度区间内的加速度和下一时刻加速度
            a_sub = a_state(k);
            a_next_sub = a_state(k + 1);   % 对应的下一时刻加速度

            % 绘制加速度和下一时刻加速度的联合分布
            try
                pd_a = fitdist(a_sub, 'Normal');
                pd_a_next = fitdist(a_next_sub, 'Normal');
            catch
                continue;
            end

            % 绘制加速度和下一时刻加速度的联合分布
            x_vals = linspace(min(a_sub), max(a_sub), 200);
            y_vals = pdf(pd_a, x_vals);

            % 用正态分布拟合 a_{t+1} 的条件分布
            x_vals_next = linspace(min(a_next_sub), max(a_next_sub), 200);
            y_vals_next = pdf(pd_a_next, x_vals_next);

            % 绘制联合分布图
            plot(x_vals, y_vals, 'LineWidth', 2, 'DisplayName', 'a_t');
            plot(x_vals_next, y_vals_next, 'LineWidth', 2, 'DisplayName', 'a_{t+1}');
            hold on

            % 图例用区间中心值表示“当前速度代表值”
            bin_center_v = (lo_v + hi_v) / 2;
            legend_entries{end+1} = sprintf('v ≈ %.3f ( [%g, %g) )', bin_center_v, lo_v, hi_v);
        end

    end

    title([states{state_idx}, '：速度区间内加速度和下一时刻加速度的联合分布']);
    xlabel('加速度 a_t / 下一时刻加速度 a_{t+1}');
    ylabel('概率密度');

    if ~isempty(legend_entries)
        legend(legend_entries, 'Location', 'best');
    else
        legend('off');
        text(0.5, 0.5, '该状态下没有满足样本数的速度区间', 'Units', 'normalized', 'HorizontalAlignment', 'center');
    end
    hold off
end
%% 二维直方图
states = {'巡航状态', '急减速状态', '急加速状态', '慢加速', '满减速', '未知状态'};
data_sets = {cruise_state, rapid_deceleration_state, rapid_acceleration_state, ...
    slow_acceleration_state, full_deceleration_state};

% 参数：按“当前速度”分箱
speed_bin_width = 10;  % 每个速度区间10为单位
min_pts = 5;  % 每个箱最少样本数，避免过拟合/拟合失败

for state_idx = 4  % 这里只选择一个状态进行演示
    current_data = data_sets{state_idx};
    v_state = current_data.speed;     % 速度数据
    a_state = current_data.tan_acc(:); % 加速度数据

    if isempty(a_state), continue; end

    % 为 v_state 构建速度分箱边界
    v_min = min(v_state);
    v_max = max(v_state);
    left = floor(v_min / speed_bin_width) * speed_bin_width;
    right = ceil(v_max / speed_bin_width) * speed_bin_width;
    v_edges = left:speed_bin_width:right;

    % 遍历每个“当前速度”的区间
    for i = 1:numel(v_edges)-1
        lo_v = v_edges(i);
        hi_v = v_edges(i+1);
        figure;  % 创建新的图形

        % 筛选出当前速度区间内的加速度数据
        k = find(v_state >= lo_v & v_state < hi_v);

        % 确保有足够的数据用于下一时刻加速度，并且k不越界
        if numel(k) >= min_pts && all(k + 1 <= numel(a_state))  % 确保k+1不会越界
            % 获取该速度区间内的加速度和下一时刻加速度
            a_sub = a_state(k);
            a_next_sub = a_state(k + 1);   % 对应的下一时刻加速度

            % 计算加速度和下一时刻加速度的二维频率分布
            [N, edges_a, edges_a_next] = histcounts2(a_sub, a_next_sub, 50);  % 50表示分成50个区间，可以根据需要调整

            % 计算每个单元格的宽度
            bin_width_x = diff(edges_a(1:2));  % x轴上每个箱子的宽度
            bin_width_y = diff(edges_a_next(1:2));  % y轴上每个箱子的宽度

            % 计算总样本数（总计数）
            total_samples = sum(N(:));  % 所有计数的总和

            % 计算概率密度
            prob_density = N / (total_samples * bin_width_x * bin_width_y);  % 归一化处理，转换为概率密度

            % 创建一个坐标网格用于绘图
            [X, Y] = meshgrid(edges_a(1:end-1) + bin_width_x / 2, edges_a_next(1:end-1) + bin_width_y / 2);

            % 绘制二维热力图（概率密度图）
            surf(X, Y, prob_density', 'EdgeColor', 'none');
            view(2);  % 使图像以俯视角度显示
            colorbar; % 显示色条
            title(sprintf('v ≈ %.3f ( [%g, %g) )', (lo_v + hi_v) / 2, lo_v, hi_v));
            xlabel('加速度 a_t');
            ylabel('下一时刻加速度 a_{t+1}');
            zlabel('概率密度');
            grid on;
            hold off; % 每个速度区间绘制一次图后清除保持
            xlim([0, 2]);
            ylim([0, 2]);
        end
    end
end
%%
% ===== Configuration =====
states = {'Cruise', 'Rapid Deceleration', 'Rapid Acceleration', 'Slow Acceleration', 'Full Deceleration', 'Unknown'};
data_sets = {cruise_state, rapid_deceleration_state, rapid_acceleration_state, ...
    slow_acceleration_state, full_deceleration_state};

state_idx = 4;     % ← Select the driving state to analyze (example: Slow Acceleration)
speed_bin_width = 10;  % Speed bin width
min_pts = 5;           % Minimum number of samples per bin
nbins = 50;            % Number of bins for 2D histogram

% ===== Load data =====
current_data = data_sets{state_idx};
v_state = current_data.speed(:);
a_state = current_data.tan_acc(:);

if isempty(a_state)
    error('No data available for this state.');
end

% ===== Build speed bin edges =====
v_min = min(v_state);
v_max = max(v_state);
left  = floor(v_min / speed_bin_width) * speed_bin_width;
right = ceil(v_max  / speed_bin_width) * speed_bin_width;
v_edges = left:speed_bin_width:right;

% ===== Pre-compute 2D densities for each speed bin (to normalize color scale) =====
bin_results = struct('X',{},'Y',{},'PD',{},'lo_v',{},'hi_v',{},'v_center',{});
max_pd = 0;

for i = 1:numel(v_edges)-1
    lo_v = v_edges(i);
    hi_v = v_edges(i+1);

    k = find(v_state >= lo_v & v_state < hi_v);

    % Sample check (and ensure k+1 does not exceed length)
    if numel(k) < min_pts || ~all(k + 1 <= numel(a_state))
        continue;
    end

    a_sub = a_state(k);
    a_next_sub = a_state(k + 1);

    % Compute 2D frequency counts (try nbins mode first; fallback to edges if not supported)
    try
        [N, edges_a, edges_a_next] = histcounts2(a_sub, a_next_sub, nbins);
    catch
        a_min = min(a_sub); a_max = max(a_sub);
        b_min = min(a_next_sub); b_max = max(a_next_sub);
        if a_min == a_max
            delta = max(abs(a_min)*1e-3, 1e-6); a_min = a_min - delta; a_max = a_max + delta;
        end
        if b_min == b_max
            delta = max(abs(b_min)*1e-3, 1e-6); b_min = b_min - delta; b_max = b_max + delta;
        end
        edges_a      = linspace(a_min, a_max, nbins+1);
        edges_a_next = linspace(b_min, b_max, nbins+1);
        [N, edges_a, edges_a_next] = histcounts2(a_sub, a_next_sub, edges_a, edges_a_next);
    end

    % Normalize to probability density
    bin_width_x = diff(edges_a(1:2));
    bin_width_y = diff(edges_a_next(1:2));
    total_samples = sum(N(:));
    PD = N / (max(total_samples,1) * bin_width_x * bin_width_y);

    % Compute grid centers
    [X, Y] = meshgrid(edges_a(1:end-1) + bin_width_x/2, ...
                      edges_a_next(1:end-1) + bin_width_y/2);

    % Store results
    bin_results(end+1) = struct( ...
        'X', X, 'Y', Y, 'PD', PD, ...
        'lo_v', lo_v, 'hi_v', hi_v, 'v_center', (lo_v+hi_v)/2 ); %#ok<SAGROW>

    max_pd = max(max_pd, max(PD(:)));
end

n_valid = numel(bin_results);
if n_valid == 0
    error('No valid speed bins with enough samples for this state.');
end

% ===== Plot all bins in a single figure =====
% Approximate square grid: columns = ceil(sqrt(n)), rows accordingly
ncols = ceil(sqrt(n_valid));
nrows = ceil(n_valid / ncols);

fig = figure('Color','w','Units','normalized','Position',[0.05 0.05 0.9 0.85]);
t = tiledlayout(nrows, ncols, 'Padding','compact', 'TileSpacing','compact');
sgtitle(t, sprintf('%s | 2D Probability Density across Speed Bins (nbins=%d)', states{state_idx}, nbins), ...
    'FontWeight','bold');

colormap(parula);   % Set global colormap

for j = 1:n_valid
    ax = nexttile;  % Get current axes handle
    surf(ax, bin_results(j).X, bin_results(j).Y, bin_results(j).PD', 'EdgeColor','none');
    view(ax, 2); axis(ax, 'square'); grid(ax, 'on');

    xlim(ax, [0, 2]);
    ylim(ax, [0, 2]);

    % Optionally unify all color scales for better comparison
    caxis(ax, [0, max_pd]);

    title(ax, sprintf('v≈%.2f  ( [%.1f, %.1f) )', ...
        bin_results(j).v_center, bin_results(j).lo_v, bin_results(j).hi_v));
    xlabel(ax, 'Acceleration a_t');
    ylabel(ax, 'Next-step Acceleration a_{t+1}');

    % —— Independent colorbar for each subplot ——
    cb = colorbar(ax, 'eastoutside');
    cb.Label.String = 'Probability Density';
end


%%
states = {'巡航状态', '急减速状态', '急加速状态', '慢加速', '满减速', '未知状态'};
data_sets = {cruise_state, rapid_deceleration_state, rapid_acceleration_state, ...
    slow_acceleration_state, full_deceleration_state};

% 参数：按“当前速度”分箱
speed_bin_width = 10;  % 每个速度区间10为单位
min_pts = 5;           % 每个箱最少样本数
nbins = 50;            % 二维分布分成50个区间

for state_idx = 4  % 这里只选择一个状态进行演示
    current_data = data_sets{state_idx};
    v_state = current_data.speed(:);
    a_state = current_data.tan_acc(:);

    if isempty(a_state), continue; end

    % 构建速度分箱边界
    v_min = min(v_state);
    v_max = max(v_state);
    left  = floor(v_min / speed_bin_width) * speed_bin_width;
    right = ceil(v_max  / speed_bin_width) * speed_bin_width;
    v_edges = left:speed_bin_width:right;

    for i = 1:numel(v_edges)-1
        lo_v = v_edges(i);
        hi_v = v_edges(i+1);
        k = find(v_state >= lo_v & v_state < hi_v);

        if numel(k) >= min_pts && all(k + 1 <= numel(a_state))
            a_sub = a_state(k);
            a_next_sub = a_state(k + 1);

            % figure 设置
            fig = figure('Color','w','Units','normalized','Position',[0.15 0.08 0.6 0.8]);
            % sgtitle(sprintf('%s｜速度区间 [%.1f, %.1f)（v≈%.3f）', ...
            %     states{state_idx}, lo_v, hi_v, (lo_v+hi_v)/2), 'FontWeight','bold');

            % ======== 上方子图：一维 PDF（窄但与下方同宽） ========
            ax1 = axes('Parent',fig,'Position',[0.285 0.67 0.4 0.12]); % 宽度相同，高度较窄
            hold(ax1,'on'); grid(ax1,'on');

            try
                pd_a      = fitdist(a_sub, 'Normal');
                pd_a_next = fitdist(a_next_sub, 'Normal');
            catch
                close(fig);
                continue;
            end

            x_lo = min([a_sub; a_next_sub]);
            x_hi = max([a_sub; a_next_sub]);
            pad  = 0.05*(x_hi - x_lo + eps);
            x_vals = linspace(x_lo - pad, x_hi + pad, 400);
            % 为每个速度区间生成不同颜色
            colors = lines(numel(v_edges)-1);  % 使用lines色彩图
            current_color = colors(i, :);

            % 或者使用其他色彩图：
            % colors = parula(numel(v_edges)-1);
            % colors = hsv(numel(v_edges)-1);
            % colors = jet(numel(v_edges)-1);

            % 在显示名称中包含速度区间信息
            % speed_range_label = sprintf('a (t) [%.1f,%.1f)', lo_v, hi_v);

            % plot(ax1, x_vals, pdf(pd_a, x_vals), 'LineWidth', 2, 'DisplayName', 'a_t', 'Color', current_color);
            plot(ax1, x_vals, pdf(pd_a_next, x_vals), 'LineWidth', 2, 'Color', current_color);
            xlabel(ax1,'a (t)');
            ylabel(ax1,' Probability Density');
            % title(ax1,'一维概率密度分布（上方较窄）');
            % legend(ax1,'Location','best');
           % ======== 下方子图：二维概率密度（正方形） ========
            ax2 = axes('Parent',fig,'Position',[0.15 0.10 0.70 0.50]); % 同宽更高
            hold(ax2,'on'); grid(ax2,'on');

            % 计算二维频率分布
            try
                [N, edges_a, edges_a_next] = histcounts2(a_sub, a_next_sub, nbins);
            catch
                a_min = min(a_sub); a_max = max(a_sub);
                b_min = min(a_next_sub); b_max = max(a_next_sub);
                if a_min == a_max, delta = max(abs(a_min)*1e-3,1e-6); a_min=a_min-delta; a_max=a_max+delta; end
                if b_min == b_max, delta = max(abs(b_min)*1e-3,1e-6); b_min=b_min-delta; b_max=b_max+delta; end
                edges_a = linspace(a_min, a_max, nbins+1);
                edges_a_next = linspace(b_min, b_max, nbins+1);
                [N, edges_a, edges_a_next] = histcounts2(a_sub, a_next_sub, edges_a, edges_a_next);
            end

            bin_width_x = diff(edges_a(1:2));
            bin_width_y = diff(edges_a_next(1:2));
            total_samples = sum(N(:));
            prob_density = N / (max(total_samples,1) * bin_width_x * bin_width_y);

            [X, Y] = meshgrid(edges_a(1:end-1)+bin_width_x/2, ...
                              edges_a_next(1:end-1)+bin_width_y/2);

            surf(ax2, X, Y, prob_density', 'EdgeColor', 'none');
            view(ax2, 2);
            colorbar(ax2);
            % title(ax2, sprintf('v ≈ %.3f ( [%.1f, %.1f) )', (lo_v + hi_v)/2, lo_v, hi_v));
            xlabel(ax2,'a (t)');
            ylabel(ax2,'a (t-1)');
            zlabel(ax2,' Probability Density');
            axis(ax2,'square');
            xlim(ax2,[0, 2]); ylim(ax2,[0, 2]);
        end
    end
end

%%
% —— 假定你已读入数据并拿到以下变量 ——
time = data_new.time;
v    = data_new_1lane.speed;     % 速度
a    = data_new_1lane.tan_acc;   % 加速度
% 1) 按条件筛选：加速度 [-25,10]，速度 <= 70
mask = (a >= -25 & a <= 5) & (v <= 70) & ~isnan(a) & ~isnan(v);
v_filt = v(mask);
a_filt = a(mask);

if isempty(v_filt)
    error('筛选后无数据：请检查阈值或数据单位是否一致。');
end
% 2) 速度分箱（0–70）
v_min = 0;
v_max = 70;
num_bins = 70;                            % 可调整：分成多少个速度箱
v_edges = linspace(v_min, v_max, num_bins + 1);

% 最少样本阈值：每个箱内至少 N 个点才计算统计量（可按需要调节或设为 1 关闭）
min_count = 10;

% 预分配
v_centers = (v_edges(1:end-1) + v_edges(2:end)) / 2;
a_mean  = nan(1, num_bins);
a_upper = nan(1, num_bins);
a_lower = nan(1, num_bins);
n_inbin = zeros(1, num_bins);             % 记录每箱样本数，可选

% 3) 逐箱计算加速度统计量
for i = 1:num_bins
    idx = (v_filt >= v_edges(i)) & (v_filt < v_edges(i+1));
    n_inbin(i) = nnz(idx);
    if n_inbin(i) >= min_count
        ai = a_filt(idx);
        a_mean(i)  = mean(ai);
        a_upper(i) = prctile(ai, 97.5);
        a_lower(i) = prctile(ai, 2.5);
    end
end

% 可选：对包络做一点平滑（注释掉即关闭）
win = 3;
a_mean  = movmean(a_mean,  win, 'omitnan');
a_upper = movmean(a_upper, win, 'omitnan');
a_lower = movmean(a_lower, win, 'omitnan');

% 去掉 NaN 箱
valid = ~isnan(a_mean) & ~isnan(a_upper) & ~isnan(a_lower);
v_plot = v_centers(valid);
m_plot = a_mean(valid);
u_plot = a_upper(valid);
l_plot = a_lower(valid);

% 4) 绘图
figure; hold on; box on; grid on;
% 筛选后的散点
plot(v_filt, a_filt, '.', 'MarkerSize', 8, 'Color', [0.2 0.4 0.9]);

% 置信带
fill([v_plot, fliplr(v_plot)], [u_plot, fliplr(l_plot)], ...
     [0.9 0.3 0.3], 'FaceAlpha', 0.18, 'EdgeColor', 'none');

% 均值与上下边界
plot(v_plot, m_plot, 'k-', 'LineWidth', 2);
plot(v_plot, u_plot, 'r-', 'LineWidth', 1.5);
plot(v_plot, l_plot, 'r-', 'LineWidth', 1.5);

title('速度≤70 且 -25≤加速度≤10 的速度-加速度包络线');
xlabel('速度 (mph)');
ylabel('加速度 (mph/s)');
legend('筛选后数据点', '2.5–97.5% 区间', '均值', '97.5百分位', '2.5百分位', ...
       'Location', 'best');

xlim([v_min, v_max]);

% 可选：在图中标注每个箱的样本数（用于检查数据充足度）
% for i = 1:num_bins
%     if valid(i)
%         text(v_plot(i), u_plot(i), sprintf('n=%d', n_inbin(valid)(i)), ...
%             'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', 'FontSize', 7);
%     end
% end

%%
% 如果数据存储在文件中，可以使用 readtable 加载
% 例如：trajectory505 = readtable('trajectory505.csv');

% 提取时间、速度、加速度
time = data_new.Var5;          % 时间列
v = data_new.Var7;            % 速度列
a = data_new.Var8;     % 加速度列

% 将速度划分为多个区间（bins）
v_min = 0; % 最小速度
v_max = 100; % 最大速度
num_bins = 100;  % 区间数量
v_edges = linspace(v_min, v_max, num_bins + 1); % 速度区间的边界

% 初始化包络线数据
v_centers = zeros(1, num_bins); % 每个区间的中心速度
a_mean = zeros(1, num_bins);    % 每个区间的加速度均值
a_upper = zeros(1, num_bins);   % 每个区间的加速度 97.5百分位数
a_lower = zeros(1, num_bins);   % 每个区间的加速度 2.5百分位数

% 计算每个速度区间的加速度统计量
for i = 1:num_bins
    % 找到当前速度区间的数据点
    idx = (v >= v_edges(i)) & (v < v_edges(i+1));
    if any(idx)
        % 计算加速度的均值、97.5百分位数和2.5百分位数
        a_mean(i) = mean(a(idx));
        a_upper(i) = prctile(a(idx), 97.5);
        a_lower(i) = prctile(a(idx), 2.5);
        % 计算区间中心速度
        v_centers(i) = (v_edges(i) + v_edges(i+1)) / 2;
    else
        % 如果区间内没有数据点，设为 NaN
        a_mean(i) = NaN;
        a_upper(i) = NaN;
        a_lower(i) = NaN;
        v_centers(i) = (v_edges(i) + v_edges(i+1)) / 2;
    end
end

% 去除 NaN 值
valid_idx = ~isnan(a_mean) & ~isnan(a_upper) & ~isnan(a_lower);
v_centers = v_centers(valid_idx);
a_mean = a_mean(valid_idx);
a_upper = a_upper(valid_idx);
a_lower = a_lower(valid_idx);

% Plot envelope
figure;
plot(v, a, 'b.', 'MarkerSize', 10); % Original data points
hold on;
plot(v_centers, a_mean, 'k-', 'LineWidth', 2); % Mean
plot(v_centers, a_upper, 'r-', 'LineWidth', 2); % Upper boundary (97.5th percentile)
plot(v_centers, a_lower, 'r-', 'LineWidth', 2); % Lower boundary (2.5th percentile)
fill([v_centers, fliplr(v_centers)], [a_upper, fliplr(a_lower)], 'r', 'FaceAlpha', 0.2, 'EdgeColor', 'none'); % Filled region
title('Velocity-Acceleration Envelope');
xlabel('Velocity (mph)');
ylabel('Acceleration (mph/s)');
legend('Data Points', 'Mean', '97.5th Percentile', '2.5th Percentile');
grid on;


%% 筛选加速度和速度的高斯分布

% 筛选出负的加速度
neg_a = a(a < 0); % 负加速度
neg_v = v(a < 0); % 负加速度对应的速度

% 将速度划分为 [0, 60]，步长为 1 mph
v_edges = 0:1:60; % 速度区间边界
v_centers = (v_edges(1:end-1) + v_edges(2:end)) / 2; % 速度区间中心值

% 将加速度划分为 [-5, 0]，步长为 0.2 mph/s
a_edges = -5:0.2:0; % 加速度区间边界
a_centers = (a_edges(1:end-1) + a_edges(2:end)) / 2; % 加速度区间中心值

% 初始化高斯分布矩阵
pdf_matrix = zeros(length(v_centers), length(a_centers)); % 存储每个速度区间内加速度的高斯分布

% 计算每个速度区间内加速度的高斯分布
for i = 1:length(v_centers)
    % 找到当前速度区间的数据点
    v_idx = (neg_v >= v_edges(i)) & (neg_v < v_edges(i+1));
    if any(v_idx)
        % 计算加速度的均值和标准差
        mu = mean(neg_a(v_idx));
        sigma = std(neg_a(v_idx));
        % 计算高斯分布
        pdf_matrix(i, :) = normpdf(a_centers, mu, sigma);
    end
end

% 绘制三维高斯分布曲线（逐条生成）
figure;

hold on;
colors = lines(length(v_centers)); % 为每个速度区间分配不同颜色
for i = 1:length(v_centers)
    % 绘制当前速度区间内加速度的高斯分布曲线
    plot3(v_centers(i) * ones(size(a_centers)), a_centers, pdf_matrix(i, :), ...
          'Color', colors(i,:), 'LineWidth', 2);
end
xlabel('速度 (mph)');
ylabel('加速度 (mph/s)');
zlabel('概率密度');
title('速度和加速度的高斯分布（逐条生成）');
view(3); % 设置视角为三维
grid on;
%%
%% === 0) 从 data_new 取加速度，并计算 jerk ===
% 假定 data_new 为 table 或矩阵，第 8 列为加速度 (m/s^2)
if istable(data_new)
    a = data_new{:, 8};
else
    a = data_new(:, 8);
end

% 基本检查
if ~isnumeric(a) || numel(a) < 2
    error('第8列加速度必须为数值且至少包含两个样本。');
end

a = a(:);                      % 保证列向量
dt = 0.04;                     % 采样间隔（按你的数据实际修改）
jerk = diff(a) ./ dt;          % jerk 定义为加速度一阶差分 / dt

% 与“当前时刻”对齐：使用 a(2:end) 对应 jerk(1..N-1)
a_curr    = a(2:end);
jerk_curr = jerk;

% 去除 NaN / Inf
valid = isfinite(a_curr) & isfinite(jerk_curr);
a_curr = a_curr(valid);
jerk_curr = jerk_curr(valid);

% === 1) 按加速度分箱，并统计 2.5%/97.5% 与均值 ===
a_min = -2;                  % 加速度下限 (m/s^2) ——按需要调整
a_max = 2;                  % 加速度上限 (m/s^2)
bin_w = 0.2;                 % 分箱宽度
edges = a_min:bin_w:a_max;   % 分箱边界
if edges(end) < a_max, edges = [edges, a_max]; end
centers = (edges(1:end-1) + edges(2:end)) / 2;

min_count = 10;              % 每箱最少样本数（避免分位数不稳定）

p2   = nan(size(centers));   % 2.5百分位
p97  = nan(size(centers));   % 97.5百分位
mC   = nan(size(centers));   % 中心平均线（均值）

for i = 1:numel(centers)
    if i < numel(centers)
        idx = (a_curr >= edges(i)) & (a_curr < edges(i+1));
    else
        % 最后一个箱包含右端点
        idx = (a_curr >= edges(i)) & (a_curr <= edges(i+1));
    end
    if nnz(idx) >= min_count
        ji   = jerk_curr(idx);
        p2(i)  = prctile(ji, 2.5);
        p97(i) = prctile(ji, 97.5);
        mC(i)  = mean(ji, 'omitnan');
    end
end

% 仅保留有效箱
ok = isfinite(p2) & isfinite(p97) & isfinite(mC);
x  = centers(ok);
yL = p2(ok);
yU = p97(ok);
yC = mC(ok);

% （可选）对中心平均线做轻微平滑，减少抖动：
% yC = movmean(yC, 3, 'omitnan');

% === 2) 绘图：原始散点 + 包络线 + 中心平均线 ===
figure; hold on; grid on;

% 原始散点（使用 scatter 更健壮）
h_scatter = scatter(a_curr, jerk_curr, 8, '.');  % 点数大时 MarkerSize 可适当减小

% 上/下包络线（97.5%、2.5%）
h_u = plot(x, yU, '-', 'LineWidth', 2);  % 默认颜色即可，避免不必要属性
h_l = plot(x, yL, '-', 'LineWidth', 2);

% 中心平均线
h_c = plot(x, yC, '-', 'LineWidth', 2);

% 设置颜色以便区分（可选，如不想显式设色可去掉这三行）
set(h_u, 'Color', [0.85 0.1 0.1]);  % 上包络：红
set(h_l, 'Color', [0.1 0.4 0.85]);  % 下包络：蓝
set(h_c, 'Color', [0.1 0.6 0.1]);   % 中心：绿

% 如需阴影区（包络间填充），可取消下方注释（含轻透明）：
% 注意：如果之前遇到“透明度”报错，先确认没有变量遮蔽函数（见下方说明）
% fill([x; flipud(x)], [yU; flipud(yL)], [0.85 0.85 0.85], ...
%      'EdgeColor','none', 'FaceAlpha', 0.25);

xlabel('Acceleration a (m/s^2)');
ylabel('Jerk (m/s^3)');
title('Jerk vs Acceleration: Envelope (2.5% / 97.5%) and Mean Center Line');

% Legend order: upper envelope, lower envelope, center, original
legend([h_u, h_l, h_c, h_scatter], ...
       {'97.5% Envelope', '2.5% Envelope', 'Mean Center Line', 'Original Data Points'}, ...
       'Location', 'best');

xlim([a_min, a_max]);
ylim([-10, 10]);
hold off;
% === 3)（可选）排查“透明度违规”/输入解析问题的小贴士 ===
% 若再次遇到 prepareAxes / 透明度相关的报错：
% 1) 确保工作区没有与图形函数同名的变量/函数，尤其是：
%    plot/line/alpha/axes/figure 等
%    可用：
%       which plot -all
%       which alpha -all
%    如发现同名变量/自定义函数遮蔽，先：
%       clear plot line alpha axes figure
%       restoredefaultpath; rehash toolboxcache;
% 2) 确保传给 plot/scatter 的 x/y 均为数值、等长列向量（本代码已统一为列向量）


%% 计算jerk
% 假设 data_new 是一个矩阵或 table，第 8 列是加速度数据
% 如果数据存储在文件中，可以使用 load 或 readmatrix 加载
% 例如：data_new = readmatrix('data_new.csv');

% 提取第 8 列的加速度数据
if istable(data_new)
    % 如果 data_new 是 table，使用 {} 提取列数据
    a = data_new{:, 8}; 
else
    % 如果 data_new 是矩阵，直接提取第 8 列
    a = data_new(:, 8); 
end

% 调试：检查提取的数据
disp('检查加速度数据:');
disp(['数据类型: ', class(a)]);
disp(['数据维度: ', num2str(size(a))]);
disp('前5个值: ');
disp(a(1:min(5, length(a))));

% 确保数据是数值类型
if ~isnumeric(a)
    error('第8列数据不是数值类型，无法计算差分');
end

% 检查数据是否有效
if isempty(a)
    error('加速度数据为空');
end

if length(a) < 2
    error('加速度数据点太少，无法计算差分（需要至少2个点）');
end

% 计算加加速度（jerk）
dt = 0.04; % 时间步长
jerk = diff(a) ./ dt; % 差分并除以时间步长

% 将 jerk 添加到数据集中
% 注意：jerk 的长度比原始数据少 1，因此需要对齐
if istable(data_new)
    % 如果 data_new 是 table，添加新列
    % 创建与 data_new 行数相同的 jerk 向量
    jerk_full = NaN(height(data_new), 1);
    jerk_full(2:end) = jerk; % 从第2行开始填充
    data_new.Jerk = jerk_full;
else
    % 如果 data_new 是矩阵，添加新列
    jerk_full = NaN(size(data_new, 1), 1);
    jerk_full(2:end) = jerk;
    data_new = [data_new, jerk_full];
end

% 显示结果
disp('加加速度（jerk）计算完成，已添加到数据集中：');
disp(['原始数据行数: ', num2str(length(a))]);
disp(['Jerk 数据行数: ', num2str(length(jerk_full))]);
disp('前10行数据预览:');
if istable(data_new)
    disp(data_new(1:min(10, height(data_new)), :));
else
    disp(data_new(1:min(10, size(data_new, 1)), :));
end%% 计算加速度和jerk的高斯分布
% 假设 data_new 是一个矩阵或 table，包含加速度和加加速度数据
% 如果数据存储在文件中，可以使用 load 或 readmatrix 加载
% 例如：data_new = readmatrix('data_new.csv');

% 提取加速度和加加速度数据
if istable(data_new)
    a = data_new{:, 8}; % 第 8 列是加速度
    jerk = data_new{:, end}; % 最后一列是加加速度
else
    a = data_new(:, 8); % 第 8 列是加速度
    jerk = data_new(:, end); % 最后一列是加加速度
end

% 去除 NaN 值（如果有）
a = a(~isnan(a));
jerk = jerk(~isnan(jerk));

% 将加速度划分为区间，步长为 0.2
a_min = -3;
a_max = 3;
a_edges = floor(a_min):0.2:ceil(a_max); % 加速度区间边界
a_centers = (a_edges(1:end-1) + a_edges(2:end)) / 2; % 加速度区间中心值

% 将加加速度划分为区间，步长为 0.2
jerk_min = -50;
jerk_max = 50;
jerk_edges = floor(jerk_min):0.2:ceil(jerk_max); % 加加速度区间边界
jerk_centers = (jerk_edges(1:end-1) + jerk_edges(2:end)) / 2; % 加加速度区间中心值

% 初始化高斯分布矩阵
pdf_matrix = zeros(length(a_centers), length(jerk_centers)); % 存储每个加速度区间内加加速度的高斯分布

% 计算每个加速度区间内加加速度的高斯分布
for i = 1:length(a_centers)
    % 找到当前加速度区间的数据点
    a_idx = (a >= a_edges(i)) & (a < a_edges(i+1));
    if any(a_idx)
        % 计算加加速度的均值和标准差
        mu = mean(jerk(a_idx));
        sigma = std(jerk(a_idx));
        % 计算高斯分布
        pdf_matrix(i, :) = normpdf(jerk_centers, mu, sigma);
    end
end

% 绘制三维高斯分布曲线（逐条生成）
figure;
hold on;
colors = lines(length(a_centers)); % 为每个加速度区间分配不同颜色
for i = 1:length(a_centers)
    if a_centers(i)<-0.1
    % 绘制当前加速度区间内加加速度的高斯分布曲线
    plot3(a_centers(i) * ones(size(jerk_centers)), jerk_centers, pdf_matrix(i, :), ...
          'Color', colors(i,:), 'LineWidth', 2);
    end
end
xlabel('加速度 (m/s²)');
ylabel('加加速度 (m/s³)');
zlabel('概率密度');
title('加速度和加加速度的高斯分布（逐条生成）');
view(3); % 设置视角为三维
grid on;


%% at-1和at的高斯分布


% 初始化 a(t-1) 和 a(t) 的数据
a_t_minus_1_all = []; % 存储所有车辆的 a(t-1)
a_t_all = []; % 存储所有车辆的 a(t)

% 遍历每辆车的轨迹数据
for i = 1:length(selected_trajectories)
    % 提取当前车辆的加速度数据（第 4 列）
    a = selected_trajectories{i}(:, 4);
    
    % 提取 a(t-1) 和 a(t)
    a_t_minus_1 = a(1:end-1); % a(t-1)
    a_t = a(2:end); % a(t)
    
    % 将当前车辆的 a(t-1) 和 a(t) 添加到全局数据中
    a_t_minus_1_all = [a_t_minus_1_all; a_t_minus_1];
    a_t_all = [a_t_all; a_t];
end

% 限制 a(t) 和 a(t-1) 的范围在 [-3, 3] 之间
valid_idx = (a_t_all >= -3) & (a_t_all <= 3) & (a_t_minus_1_all >= -3) & (a_t_minus_1_all <= 3);
a_t_all = a_t_all(valid_idx);
a_t_minus_1_all = a_t_minus_1_all(valid_idx);

% 将 a(t-1) 划分为区间，步长为 0.2
a_t_minus_1_min = -3; % 最小 a(t-1)
a_t_minus_1_max = 3; % 最大 a(t-1)
a_t_minus_1_edges = a_t_minus_1_min:0.2:a_t_minus_1_max; % a(t-1) 区间边界
a_t_minus_1_centers = (a_t_minus_1_edges(1:end-1) + a_t_minus_1_edges(2:end)) / 2; % a(t-1) 区间中心值

% 初始化高斯分布矩阵
pdf_matrix = zeros(length(a_t_minus_1_centers), 1000); % 存储每个 a(t-1) 区间内 a(t) 的高斯分布

% 计算每个 a(t-1) 区间内 a(t) 的高斯分布
for i = 1:length(a_t_minus_1_centers)
    % 找到当前 a(t-1) 区间的数据点
    idx = (a_t_minus_1_all >= a_t_minus_1_edges(i)) & (a_t_minus_1_all < a_t_minus_1_edges(i+1));
    if any(idx)
        % 计算 a(t) 的均值和标准差
        mu = mean(a_t_all(idx));
        sigma = std(a_t_all(idx));
        % 生成高斯分布曲线
        x = linspace(-3, 3, 1000); % a(t) 的范围限制在 [-3, 3]
        pdf_matrix(i, :) = normpdf(x, mu, sigma); % 高斯分布
    end
end

% 绘制三维高斯分布曲线（a(t-1) < 0 和 a(t-1) > 0 分开画图）
figure;

% a(t-1) < 0 的情况
% subplot(1, 2, 1);
hold on;
colors = lines(sum(a_t_minus_1_centers < 0)); % 为每个 a(t-1) < 0 的区间分配不同颜色
for i = 1:length(a_t_minus_1_centers)
    if a_t_minus_1_centers(i) < 0
        % 绘制当前 a(t-1) 区间内 a(t) 的高斯分布曲线
        plot3(x, a_t_minus_1_centers(i) * ones(size(x)), pdf_matrix(i, :), 'LineWidth', 2);
    end
end
xlabel('a(t) (m/s²)');
ylabel('a(t-1) (m/s²)');
zlabel('概率密度');
title('a(t-1) < 0 时 a(t) 的高斯分布');
view(3); % 设置视角为三维
grid on;
figure;
% % a(t-1) > 0 的情况
% subplot(1, 2, 2);
hold on;
colors = lines(sum(a_t_minus_1_centers > 0)); % 为每个 a(t-1) > 0 的区间分配不同颜色
for i = 1:length(a_t_minus_1_centers)
    if a_t_minus_1_centers(i) > 0
        % 绘制当前 a(t-1) 区间内 a(t) 的高斯分布曲线
        plot3(x, a_t_minus_1_centers(i) * ones(size(x)), pdf_matrix(i, :),  'LineWidth', 2);
    end
end
xlabel('a(t) (m/s²)');
ylabel('a(t-1) (m/s²)');
zlabel('概率密度');
title('a(t-1) > 0 时 a(t) 的高斯分布');
view(3); % 设置视角为三维
grid on;
%%  vt-1和vt的高斯分布
% 初始化 v(t-1) 和 v(t) 的数据
v_t_minus_1_all = []; % 存储所有车辆的 v(t-1)
v_t_all = []; % 存储所有车辆的 v(t)

% 遍历每辆车的轨迹数据
for i = 1:length(selected_trajectories)
    % 提取当前车辆的速度数据（假设第 3 列是速度）
    v = selected_trajectories{i}(:, 3);
    
    % 提取 v(t-1) 和 v(t)
    v_t_minus_1 = v(1:end-1); % v(t-1)
    v_t = v(2:end); % v(t)
    
    % 将当前车辆的 v(t-1) 和 v(t) 添加到全局数据中
    v_t_minus_1_all = [v_t_minus_1_all; v_t_minus_1];
    v_t_all = [v_t_all; v_t];
end

% 限制 v(t) 和 v(t-1) 的范围大于 0
valid_idx = (v_t_all > 0) & (v_t_minus_1_all > 0);
v_t_all = v_t_all(valid_idx);
v_t_minus_1_all = v_t_minus_1_all(valid_idx);

% 将 v(t-1) 划分为区间，步长为 0.2
v_t_minus_1_min = min(v_t_minus_1_all); % 最小 v(t-1)
v_t_minus_1_max = max(v_t_minus_1_all); % 最大 v(t-1)
v_t_minus_1_edges = floor(v_t_minus_1_min):0.2:ceil(v_t_minus_1_max); % v(t-1) 区间边界
v_t_minus_1_centers = (v_t_minus_1_edges(1:end-1) + v_t_minus_1_edges(2:end)) / 2; % v(t-1) 区间中心值

% 初始化高斯分布矩阵
pdf_matrix = zeros(length(v_t_minus_1_centers), 1000); % 存储每个 v(t-1) 区间内 v(t) 的高斯分布

% 计算每个 v(t-1) 区间内 v(t) 的高斯分布
for i = 1:length(v_t_minus_1_centers)
    % 找到当前 v(t-1) 区间的数据点
    idx = (v_t_minus_1_all >= v_t_minus_1_edges(i)) & (v_t_minus_1_all < v_t_minus_1_edges(i+1));
    if any(idx)
        % 计算 v(t) 的均值和标准差
        mu = mean(v_t_all(idx));
        sigma = std(v_t_all(idx));
        % 生成高斯分布曲线
        x = linspace(min(v_t_all), max(v_t_all), 1000); % v(t) 的范围
        pdf_matrix(i, :) = normpdf(x, mu, sigma); % 高斯分布
    end
end

% 绘制三维高斯分布曲线
figure;
hold on;
colors = lines(length(v_t_minus_1_centers)); % 为每个 v(t-1) 区间分配不同颜色
for i = 1:length(v_t_minus_1_centers)
    % 绘制当前 v(t-1) 区间内 v(t) 的高斯分布曲线
    plot3(x, v_t_minus_1_centers(i) * ones(size(x)), pdf_matrix(i, :), ...
          'Color', colors(i, :), 'LineWidth', 2);
end
xlabel('v(t) (m/s)');
ylabel('v(t-1) (m/s)');
zlabel('概率密度');
title('v(t-1) 和 v(t) 的高斯分布');
view(3); % 设置视角为三维
grid on;
%% 马尔科夫链转移
% 初始化 a(t-1) 和 a(t) 的数据
a_t_minus_1_all = []; % 存储所有车辆的 a(t-1)
a_t_all = []; % 存储所有车辆的 a(t)

% 遍历每辆车的轨迹数据
for i = 1:length(selected_trajectories)
    % 提取当前车辆的加速度数据（第 4 列）
    a = selected_trajectories{i}(:, 4);
    
    % 提取 a(t-1) 和 a(t)
    a_t_minus_1 = a(1:end-1); % a(t-1)
    a_t = a(2:end); % a(t)
    
    % 将当前车辆的 a(t-1) 和 a(t) 添加到全局数据中
    a_t_minus_1_all = [a_t_minus_1_all; a_t_minus_1];
    a_t_all = [a_t_all; a_t];
end

% 限制 a(t) 和 a(t-1) 的范围在 [-3, 3] 之间
valid_idx = (a_t_all >= -3) & (a_t_all <= 3) & (a_t_minus_1_all >= -3) & (a_t_minus_1_all <= 3);
a_t_all = a_t_all(valid_idx);
a_t_minus_1_all = a_t_minus_1_all(valid_idx);

% 将 a(t-1) 划分为区间，步长为 0.2
a_t_minus_1_min = -3; % 最小 a(t-1)
a_t_minus_1_max = 3; % 最大 a(t-1)
a_t_minus_1_edges = a_t_minus_1_min:0.2:a_t_minus_1_max; % a(t-1) 区间边界
a_t_minus_1_centers = (a_t_minus_1_edges(1:end-1) + a_t_minus_1_edges(2:end)) / 2; % a(t-1) 区间中心值

% 将 a(t-1) 和 a(t) 分配到对应的区间
a_t_minus_1_bins = discretize(a_t_minus_1_all, a_t_minus_1_edges);
a_t_bins = discretize(a_t_all, a_t_minus_1_edges);

% 初始化转移次数矩阵
num_bins = length(a_t_minus_1_centers); % 区间数量
transition_counts = zeros(num_bins, num_bins);

% 统计转移次数
for k = 1:length(a_t_minus_1_bins)
    if ~isnan(a_t_minus_1_bins(k)) && ~isnan(a_t_bins(k))
        transition_counts(a_t_minus_1_bins(k), a_t_bins(k)) = ...
            transition_counts(a_t_minus_1_bins(k), a_t_bins(k)) + 1;
    end
end

% 计算转移概率矩阵
transition_prob = transition_counts ./ sum(transition_counts, 2);

% 处理 NaN 值（如果某一行全为 0，则概率为 0）
transition_prob(isnan(transition_prob)) = 0;

% 显示转移概率矩阵
disp('转移概率矩阵:');
disp(transition_prob);

% 可视化转移概率矩阵
figure;
imagesc(transition_prob);
colorbar;
xlabel('a(t) 区间');
ylabel('a(t-1) 区间');
title('马尔可夫链转移概率矩阵');
set(gca, 'XTick', 1:num_bins, 'XTickLabel', a_t_minus_1_centers);
set(gca, 'YTick', 1:num_bins, 'YTickLabel', a_t_minus_1_centers);

% 生成马尔可夫链（示例：从某个初始状态开始模拟）
initial_state = 1; % 初始状态（区间索引）
num_steps = 100; % 模拟步数
markov_chain = zeros(1, num_steps);
markov_chain(1) = initial_state;

for t = 2:num_steps
    % 根据转移概率矩阵选择下一个状态
    markov_chain(t) = randsample(num_bins, 1, true, transition_prob(markov_chain(t-1), :));
end

% 显示马尔可夫链
disp('生成的马尔可夫链:');
disp(markov_chain);

% 可视化马尔可夫链
figure;
plot(markov_chain, 'o-');
xlabel('时间步');
ylabel('状态（区间索引）');
title('生成的马尔可夫链');
set(gca, 'YTick', 1:num_bins, 'YTickLabel', a_t_minus_1_centers);
grid on;
%% 生成速度的加速度马尔可夫
speed_min = 0; % 最小速度
speed_max = 60; % 最大速度
speed_step = 10; % 速度区间步长
speed_edges = speed_min:speed_step:speed_max; % 速度区间边界
speed_centers = (speed_edges(1:end-1) + speed_edges(2:end)) / 2; % 速度区间中心值
% 初始化存储每个速度区间的转移概率矩阵
transition_prob_cell = cell(length(speed_centers), 1);

% 遍历每个速度区间
for s = 1:length(speed_centers)
    % 提取当前速度区间内的数据
    speed_lower = speed_edges(s);
    speed_upper = speed_edges(s+1);
    
    % 初始化当前速度区间的 a(t-1) 和 a(t)
    a_t_minus_1_current = [];
    a_t_current = [];
    
    % 遍历每辆车的轨迹数据
    for i = 1:length(selected_trajectories)
        % 提取当前车辆的速度和加速度数据
        speed = selected_trajectories{i}(:, 3); % 速度（假设在第 3 列）
        a = selected_trajectories{i}(:, 4); % 加速度（假设在第 4 列）
        
        % 找到当前速度区间内的数据点
        valid_speed_idx = (speed >= speed_lower) & (speed < speed_upper);
        
        % 提取当前速度区间内的 a(t-1) 和 a(t)
        a_t_minus_1_current = [a_t_minus_1_current; a(1:end-1)];
        a_t_current = [a_t_current; a(2:end)];
    end
    
    % 限制 a(t) 和 a(t-1) 的范围在 [-3, 3] 之间
    valid_idx = (a_t_current >= -3) & (a_t_current <= 3) & ...
                (a_t_minus_1_current >= -3) & (a_t_minus_1_current <= 3);
    a_t_current = a_t_current(valid_idx);
    a_t_minus_1_current = a_t_minus_1_current(valid_idx);
    
    % 将 a(t-1) 划分为区间，步长为 0.2
    a_t_minus_1_edges = -3:0.2:3; % a(t-1) 区间边界
    a_t_minus_1_centers = (a_t_minus_1_edges(1:end-1) + a_t_minus_1_edges(2:end)) / 2; % 区间中心值
    
    % 将 a(t-1) 和 a(t) 分配到对应的区间
    a_t_minus_1_bins = discretize(a_t_minus_1_current, a_t_minus_1_edges);
    a_t_bins = discretize(a_t_current, a_t_minus_1_edges);
    
    % 初始化转移次数矩阵
    num_bins = length(a_t_minus_1_centers);
    transition_counts = zeros(num_bins, num_bins);
    
    % 统计转移次数
    for k = 1:length(a_t_minus_1_bins)
        if ~isnan(a_t_minus_1_bins(k)) && ~isnan(a_t_bins(k))
            transition_counts(a_t_minus_1_bins(k), a_t_bins(k)) = ...
                transition_counts(a_t_minus_1_bins(k), a_t_bins(k)) + 1;
        end
    end
    
    % 计算转移概率矩阵
    transition_prob = transition_counts ./ sum(transition_counts, 2);
    transition_prob(isnan(transition_prob)) = 0; % 处理 NaN 值
    
    % 存储当前速度区间的转移概率矩阵
    transition_prob_cell{s} = transition_prob;
end
for s = 1:length(speed_centers)
    figure;
    imagesc(transition_prob_cell{s});
    colorbar;
    xlabel('a(t) 区间');
    ylabel('a(t-1) 区间');
    title(['速度区间 [', num2str(speed_edges(s)), ', ', num2str(speed_edges(s+1)), ') 的转移概率矩阵']);
    set(gca, 'XTick', 1:num_bins, 'XTickLabel', a_t_minus_1_centers);
    set(gca, 'YTick', 1:num_bins, 'YTickLabel', a_t_minus_1_centers);
end
%% vt-1和vt的马尔科夫
% 初始化 v(t-1) 和 v(t) 的数据
v_t_minus_1_all = []; % 存储所有车辆的 v(t-1)
v_t_all = []; % 存储所有车辆的 v(t)

% 遍历每辆车的轨迹数据
for i = 1:length(selected_trajectories)
    % 提取当前车辆的速度数据（假设第 3 列是速度）
    v = selected_trajectories{i}(:, 3);
    
    % 提取 v(t-1) 和 v(t)
    v_t_minus_1 = v(1:end-1); % v(t-1)
    v_t = v(2:end); % v(t)
    
    % 将当前车辆的 v(t-1) 和 v(t) 添加到全局数据中
    v_t_minus_1_all = [v_t_minus_1_all; v_t_minus_1];
    v_t_all = [v_t_all; v_t];
end

% 限制 v(t) 和 v(t-1) 的范围大于 0
valid_idx = (v_t_all > 0) & (v_t_minus_1_all > 0);
v_t_all = v_t_all(valid_idx);
v_t_minus_1_all = v_t_minus_1_all(valid_idx);

% 将 v(t-1) 划分为区间，步长为 0.2
v_t_minus_1_min = min(v_t_minus_1_all); % 最小 v(t-1)
v_t_minus_1_max = max(v_t_minus_1_all); % 最大 v(t-1)
v_t_minus_1_edges = floor(v_t_minus_1_min):1:ceil(v_t_minus_1_max); % v(t-1) 区间边界
v_t_minus_1_centers = (v_t_minus_1_edges(1:end-1) + v_t_minus_1_edges(2:end)) / 2; % v(t-1) 区间中心值

% 将 v(t-1) 和 v(t) 分配到对应的区间
v_t_minus_1_bins = discretize(v_t_minus_1_all, v_t_minus_1_edges);
v_t_bins = discretize(v_t_all, v_t_minus_1_edges);

% 初始化转移次数矩阵
num_bins = length(v_t_minus_1_centers); % 区间数量
transition_counts = zeros(num_bins, num_bins);

% 统计转移次数
for k = 1:length(v_t_minus_1_bins)
    if ~isnan(v_t_minus_1_bins(k)) && ~isnan(v_t_bins(k))
        transition_counts(v_t_minus_1_bins(k), v_t_bins(k)) = ...
            transition_counts(v_t_minus_1_bins(k), v_t_bins(k)) + 1;
    end
end

% 计算转移概率矩阵
transition_prob = transition_counts ./ sum(transition_counts, 2);

% 处理 NaN 值（如果某一行全为 0，则概率为 0）
transition_prob(isnan(transition_prob)) = 0;

% 显示转移概率矩阵
disp('转移概率矩阵:');
disp(transition_prob);

% 可视化转移概率矩阵
figure;
imagesc(transition_prob);
colorbar;
xlabel('v(t) 区间');
ylabel('v(t-1) 区间');
title('马尔可夫链转移概率矩阵');
% set(gca, 'XTick', 1:num_bins, 'XTickLabel', v_t_minus_1_centers);
% set(gca, 'YTick', 1:num_bins, 'YTickLabel', v_t_minus_1_centers);

% 生成马尔可夫链（示例：从某个初始状态开始模拟）
initial_state = 1; % 初始状态（区间索引）
num_steps = 100; % 模拟步数
markov_chain = zeros(1, num_steps);
markov_chain(1) = initial_state;

for t = 2:num_steps
    % 根据转移概率矩阵选择下一个状态
    markov_chain(t) = randsample(num_bins, 1, true, transition_prob(markov_chain(t-1), :));
end

% 显示马尔可夫链
disp('生成的马尔可夫链:');
disp(markov_chain);

% 可视化马尔可夫链
figure;
plot(markov_chain, 'o-');
xlabel('时间步');
ylabel('状态（区间索引）');
title('生成的马尔可夫链');
set(gca, 'YTick', 1:num_bins, 'YTickLabel', v_t_minus_1_centers);
grid on;
%% 将马尔科夫链转移应用到对应的轨迹上
% 假设 trajectory505 是一个 table，加速度数据在第 4 列
acceleration_data = trajectory505{:, 4}; % 提取加速度数据
trajectory_length = length(acceleration_data); % 轨迹长度

% 初始化推断的加速度序列
inferred_accelerations = zeros(trajectory_length, 1);

% 获取第一个起始点的加速度值
initial_acceleration = acceleration_data(1);
inferred_accelerations(1) = initial_acceleration;

% 将起始点的加速度值映射到对应的区间
current_bin = discretize(initial_acceleration, a_t_minus_1_edges);

% 检查起始点是否在有效区间内
if isnan(current_bin)
    error('起始点的加速度值不在有效区间内。');
end

% 迭代预测剩余的加速度值
for t = 2:trajectory_length
    % 根据转移概率矩阵选择下一个区间
    next_bin = randsample(num_bins, 1, true, transition_prob(current_bin, :));
    
    % 从下一个区间中随机生成一个加速度值
    next_acceleration = a_t_minus_1_centers(next_bin) + (rand - 0.5) * bin_width;
    
    % 存储推断的加速度值
    inferred_accelerations(t) = next_acceleration;
    
    % 更新当前区间
    current_bin = next_bin;
end

% 显示结果
disp('原始加速度序列:');
disp(acceleration_data');
disp('推断的加速度序列:');
disp(inferred_accelerations');

% 可视化原始和推断的加速度序列
figure;
plot(1:trajectory_length, acceleration_data, 'b-o', 'LineWidth', 2, 'DisplayName', '原始加速度');
hold on;
plot(1:trajectory_length, inferred_accelerations, 'r--x', 'LineWidth', 2, 'DisplayName', '推断加速度');
xlabel('时间步');
ylabel('加速度 (m/s²)');
title('原始加速度 vs 推断加速度');
legend;
grid on;
%% 对加速度进行修正
% 使用全部数据预测
allInputs505 = inputs505; % 全部输入数据
allTargets505 = targets505; % 全部目标数据

allOutputs505 = net(allInputs505'); % 使用神经网络预测全部输出
allOutputs5052 = netSpeed(allInputs505'); % 使用神经网络预测全部输出
allOutputs5053 = netAcceleration(allInputs505'); % 使用神经网络预测全部输出
% 可视化对比
figure;
plot(allInputs505, allTargets505, 'b-', 'LineWidth', 2, 'DisplayName', '原始数据');
hold on;
plot(allInputs505, allOutputs505, 'r--', 'LineWidth', 2, 'DisplayName', '神经网络预测');
xlabel('时间');
ylabel('距离');
title('trajectory505: 原始数据 vs 神经网络预测');
legend;
grid on;

% 可视化对比
figure;
plot(allInputs505, speeds, 'b-', 'LineWidth', 2, 'DisplayName', '原始数据');
hold on;
plot(allInputs505, allOutputs5052, 'r--', 'LineWidth', 2, 'DisplayName', '神经网络预测');
xlabel('时间');
ylabel('距离');
title('trajectory505: 原始数据 vs 神经网络预测');
legend;
grid on;

% 可视化对比
figure;
plot(allInputs505, accelerations, 'b-', 'LineWidth', 2, 'DisplayName', '原始数据');
hold on;
plot(allInputs505, allOutputs5053, 'r--', 'LineWidth', 2, 'DisplayName', '神经网络预测');
xlabel('时间');
ylabel('距离');
title('trajectory505: 原始数据 vs 神经网络预测');
legend;
grid on;
%% 生成速度和加速度的最大值最小值拟合

% 假设 v 是速度数据，a 是加速度数据
% v 和 a 是列向量，且长度相同

% 将速度划分为 [0, 60]，步长为 1 mph
v_edges = 0:1:60; % 速度区间边界
v_centers = (v_edges(1:end-1) + v_edges(2:end)) / 2; % 速度区间中心值

% 将加速度划分为 [-5, 5]，步长为 0.2 mph/s
a_edges = -5:0.2:5; % 加速度区间边界
a_centers = (a_edges(1:end-1) + a_edges(2:end)) / 2; % 加速度区间中心值

% 初始化存储统计量的结构体
stats = struct(); % 统计量

% 计算每个速度区间内的加速度统计量
for i = 1:length(v_centers)
    % 筛选出当前速度区间内的加速度数据
    v_mask = (v >= v_edges(i)) & (v < v_edges(i+1));
    a_in_bin = a(v_mask);
    
    % 计算统计量
    if ~isempty(a_in_bin)
        stats(i).min = min(a_in_bin); % 最小值
        stats(i).max = max(a_in_bin); % 最大值
        stats(i).Q1 = quantile(a_in_bin, 0.25); % 25% 分位数
        stats(i).Q3 = quantile(a_in_bin, 0.75); % 75% 分位数
    else
        stats(i).min = NaN;
        stats(i).max = NaN;
        stats(i).Q1 = NaN;
        stats(i).Q3 = NaN;
    end
end

% 输出统计量
disp('速度和加速度统计量：');
disp('速度区间中心值 | 最小值 | 最大值 | Q1 (25%) | Q3 (75%)');
for i = 1:length(v_centers)
    fprintf('%.1f mph\t\t%.2f\t%.2f\t%.2f\t\t%.2f\n', ...
        v_centers(i), stats(i).min, stats(i).max, stats(i).Q1, stats(i).Q3);
end

% 绘制加速度的箱型图（按速度区间分组）
figure;
boxplot(a, discretize(v, v_edges), 'positions', v_centers, 'labels', v_centers);
xlabel('速度 (mph)');
ylabel('加速度 (mph/s)');
title('加速度的箱型图（按速度区间分组）');
grid on;
%% 生成拟合曲线



% 筛选出正加速度和负加速度
pos_a = a(a > 0); % 正加速度
pos_v = v(a > 0); % 正加速度对应的速度
neg_a = a(a < 0); % 负加速度
neg_v = v(a < 0); % 负加速度对应的速度

% 将速度划分为 [0, 60]，步长为 1 mph
v_edges = 0:1:60; % 速度区间边界
v_centers = (v_edges(1:end-1) + v_edges(2:end)) / 2; % 速度区间中心值

% 初始化存储 Q1 和 Q3 的数组
q1_neg = zeros(size(v_centers)); % 负加速度 Q1
q3_neg = zeros(size(v_centers)); % 负加速度 Q3
q1_pos = zeros(size(v_centers)); % 正加速度 Q1
q3_pos = zeros(size(v_centers)); % 正加速度 Q3

% 计算每个区间的 Q1 和 Q3
for i = 1:length(v_centers)
    % 负加速度
    v_mask_neg = (neg_v >= v_edges(i)) & (neg_v < v_edges(i+1));
    a_in_bin_neg = neg_a(v_mask_neg);
    if ~isempty(a_in_bin_neg)
        q1_neg(i) = quantile(a_in_bin_neg, 0.25); % Q1
        q3_neg(i) = quantile(a_in_bin_neg, 0.75); % Q3
    else
        q1_neg(i) = NaN;
        q3_neg(i) = NaN;
    end
    
    % 正加速度
    v_mask_pos = (pos_v >= v_edges(i)) & (pos_v < v_edges(i+1));
    a_in_bin_pos = pos_a(v_mask_pos);
    if ~isempty(a_in_bin_pos)
        q1_pos(i) = quantile(a_in_bin_pos, 0.25); % Q1
        q3_pos(i) = quantile(a_in_bin_pos, 0.75); % Q3
    else
        q1_pos(i) = NaN;
        q3_pos(i) = NaN;
    end
end

% 合并 Q3
q3_combined = max(q3_neg, q3_pos); % 取正负加速度 Q3 的最大值
q1_combined = min(q1_neg, q1_pos); % 取正负加速度 Q3 的最大值

% 剔除 NaN 值
valid_idx = ~isnan(q1_neg) & ~isnan(q1_pos) & ~isnan(q3_combined);
v_centers_valid = v_centers(valid_idx);
q1_neg_valid = q1_combined(valid_idx);
q1_pos_valid = q1_pos(valid_idx);
q3_combined_valid = q3_combined(valid_idx);
% 神经网络拟合
% 准备数据
X = v_centers_valid'; % 输入特征（速度）
Y_neg = q1_combined'; % 负加速度 Q1
Y_pos = q1_pos_valid'; % 正加速度 Q1
Y_upper = q3_combined_valid'; % 合并 Q3

% 创建神经网络模型
net_neg = fitnet(10); % 单隐藏层，10 个神经元
net_pos = fitnet(10); % 单隐藏层，10 个神经元
net_upper = fitnet(10); % 单隐藏层，10 个神经元

% 配置训练集、验证集和测试集
net_neg.divideParam.trainRatio = 0.7;
net_neg.divideParam.valRatio = 0.15;
net_neg.divideParam.testRatio = 0.15;

net_pos.divideParam.trainRatio = 0.7;
net_pos.divideParam.valRatio = 0.15;
net_pos.divideParam.testRatio = 0.15;

net_upper.divideParam.trainRatio = 0.7;
net_upper.divideParam.valRatio = 0.15;
net_upper.divideParam.testRatio = 0.15;

% 训练神经网络
net_neg = train(net_neg, X, Y_neg);
net_pos = train(net_pos, X, Y_pos);
net_upper = train(net_upper, X, Y_upper);

% 预测
Y_neg_pred = net_neg(X);
Y_pos_pred = net_pos(X);
Y_upper_pred = net_upper(X);


% 计算 R²
r2_neg_nn = 1 - sum((Y_neg - Y_neg_pred).^2) / sum((Y_neg - mean(Y_neg)).^2);
r2_pos_nn = 1 - sum((Y_pos - Y_pos_pred).^2) / sum((Y_pos - mean(Y_pos)).^2);
r2_upper_nn = 1 - sum((Y_upper - Y_upper_pred).^2) / sum((Y_upper - mean(Y_upper)).^2);

% 输出 R² 值
fprintf('神经网络拟合结果：\n');
fprintf('负加速度 Q1 拟合的 R²: %.4f\n', r2_neg_nn);
fprintf('正加速度 Q1 拟合的 R²: %.4f\n', r2_pos_nn);
fprintf('合并 Q3 拟合的 R²: %.4f\n', r2_upper_nn);

% 绘制神经网络拟合曲线
figure;
hold on;
plot(X, Y_neg, 'bo', 'DisplayName', '负加速度 Q1');
plot(X, Y_neg_pred, 'b-', 'LineWidth', 2, 'DisplayName', sprintf('负加速度 Q1 神经网络拟合 (R²=%.4f)', r2_neg_nn));
% plot(X, Y_pos, 'ro', 'DisplayName', '正加速度 Q1');
% plot(X, Y_pos_pred, 'r-', 'LineWidth', 2, 'DisplayName', sprintf('正加速度 Q1 神经网络拟合 (R²=%.4f)', r2_pos_nn));
plot(X, Y_upper, 'go', 'DisplayName', '合并 Q3');
plot(X, Y_upper_pred, 'g-', 'LineWidth', 2, 'DisplayName', sprintf('合并 Q3 神经网络拟合 (R²=%.4f)', r2_upper_nn));
xlabel('速度 (mph)');
ylabel('加速度 (mph/s)');
title('神经网络拟合曲线');
legend('show');
grid on;
hold off;
%%
% 隐马尔可夫模型实现
% 初始化参数
num_states = 4;         % 设定隐含状态数量
min_accel = -3;         % 最小加速度值
max_accel = 3;          % 最大加速度值
bin_width = 0.2;        % 区间宽度
edges = min_accel:bin_width:max_accel;  % 观测区间边界
centers = (edges(1:end-1) + edges(2:end))/2; % 观测区间中心值

% 数据预处理
% 为每辆车创建独立的观测序列
obs_sequences = cell(length(selected_trajectories), 1); % 使用cell数组存储序列

for i = 1:length(selected_trajectories)
    % 提取并过滤加速度数据
    accel = selected_trajectories{i}(:, 4);
    valid_idx = (accel >= min_accel) & (accel <= max_accel);
    accel_filtered = accel(valid_idx);
    
    % 离散化为观测符号（区间索引）
    [~, obs_indices] = histc(accel_filtered, edges);
    obs_indices(obs_indices == length(edges)) = length(edges)-1; % 处理边界情况
    obs_sequences{i} = obs_indices'; % 存储为行向量
end

% 初始化HMM参数
% 随机初始化转移概率矩阵（行需要归一化）
trans_probs = rand(num_states, num_states);
trans_probs = trans_probs ./ sum(trans_probs, 2);

% 随机初始化发射概率矩阵（行需要归一化）
emission_probs = rand(num_states, length(centers));
emission_probs = emission_probs ./ sum(emission_probs, 2);

% HMM训练（Baum-Welch算法）
% 设置训练参数
max_iterations = 100;   % 最大迭代次数
tolerance = 1e-6;       % 收敛阈值

% 调用MATLAB内置训练函数
[est_trans, est_emiss] = hmmtrain(obs_sequences, trans_probs, emission_probs,...
                                  'Maxiterations', max_iterations,...
                                  'Tolerance', tolerance);

% 结果显示
% 显示估计的转移概率矩阵
disp('估计的隐含状态转移矩阵:');
disp(est_trans);

% 显示估计的发射概率矩阵
disp('估计的观测概率矩阵:');
disp(est_emiss);

% 可视化结果
% 绘制转移概率矩阵
figure;
imagesc(est_trans);
colorbar;
xlabel('目标状态');
ylabel('源状态');
title('隐含状态转移概率矩阵');
set(gca, 'XTick', 1:num_states, 'YTick', 1:num_states);

% 绘制发射概率矩阵
figure;
imagesc(est_emiss);
colorbar;
xlabel('观测区间');
ylabel('隐含状态');
title('观测概率矩阵');
set(gca, 'XTick', 1:length(centers), 'XTickLabel', centers);

% 序列生成
% 生成新序列参数
num_steps = 100;        % 生成序列长度
initial_prob = ones(1, num_states)/num_states; % 均匀初始概率

% 生成隐含状态序列和观测序列
[hidden_states, observations] = hmmgenerate(num_steps, est_trans, est_emiss,...
                                           'Statenames', 1:num_states,...
                                           'Symbols', 1:length(centers));

% 将观测符号转换为加速度值
generated_accels = centers(observations);

% 可视化生成序列
figure;
subplot(2,1,1);
plot(hidden_states, 'o-');
title('生成的隐含状态序列');
xlabel('时间步');
ylabel('隐含状态');
set(gca, 'YTick', 1:num_states);

subplot(2,1,2);
plot(generated_accels, 'o-');
title('生成的观测加速度序列');
xlabel('时间步');
ylabel('加速度值');
ylim([min_accel max_accel]);
