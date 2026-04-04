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

