
% 加载轨迹数据
allInputs505 = inputs505; % 全部输入数据
allOutputs505 = net(allInputs505'); % 使用神经网络预测全部输出
allOutputs5052 = netSpeed(allInputs505'); % 使用神经网络预测全部输出
allOutputs5053 = netAcceleration(allInputs505'); % 使用神经网络预测全部输出
% 构建新的 trajectory505
new_trajectory505 = table(allInputs505,allOutputs505', allOutputs5052', allOutputs5053', ...
    'VariableNames', {'Time', 'Distance', 'Velocity', 'Acceleration'});
% 加载轨迹数据
allInputs669 = inputs669; % 全部输入数据
allOutputs669 = net1(allInputs669); % 使用神经网络预测全部输出
allOutputs6692 = netSpeed2(allInputs669); % 使用神经网络预测全部输出
allOutputs6693 = netAcceleration2(allInputs669); % 使用神经网络预测全部输出

% 构建新的 trajectory669
new_trajectory669 = table(allInputs669', allOutputs669', allOutputs6692', allOutputs6693', ...
    'VariableNames', {'Time', 'Distance', 'Velocity', 'Acceleration'});

%% 匹配对信息
% 提取匹配对的完整信息
matched_pairs_info = table();
% 计算速度
speedA = new_trajectory505.Velocity;
speedB = new_trajectory669.Velocity;
distanceA = new_trajectory505.Acceleration;
distanceB = new_trajectory669.Acceleration;

% 遍历所有匹配对
for k = 1:size(global_path_sorted, 1)
    i = global_path_sorted(k, 1); % trajA 中的索引
    j = global_path_sorted(k, 2); % trajB 中的索引
    
    % 提取 trajA 中的点信息
    time_A = tA(i);
    position_A = pA(i);
    speed_A = speedA(i);
    acceleration_A = distanceA(i); % 注意：distanceA 实际上是加速度
    
    % 提取 trajB 中的点信息
    time_B = tB(j);
    position_B = pB(j);
    speed_B = speedB(j);
    acceleration_B = distanceB(j); % 注意：distanceB 实际上是加速度
    
    % 将匹配对信息存储为一行
    matched_pair_info = table(...
        time_A, position_A, speed_A, acceleration_A, ...
        time_B, position_B, speed_B, acceleration_B, ...
        'VariableNames', {...
        'Time_A', 'Position_A', 'Speed_A', 'Acceleration_A', ...
        'Time_B', 'Position_B', 'Speed_B', 'Acceleration_B'});
    
    % 将当前匹配对信息添加到总表中
    matched_pairs_info = [matched_pairs_info; matched_pair_info];
end

% 显示前10个匹配对的完整信息
disp('前10个匹配对的完整信息：');
disp(head(matched_pairs_info, 10));

% 保存匹配对信息到CSV文件（可选）
writetable(matched_pairs_info, 'matched_pairs_full_info.csv');
%%
% 假设 fixed_points 是一个 n x 2 的矩阵，每行表示一个固定点的 [时间, 位置]
% 假设 matched_pairs_info 是之前计算的匹配对信息表格
fixed_points = vehiclesInRangeAt550m1; % 固定检测点坐标  

% 筛选出 unchanging_points 对应的固定点
% 假设 unchanging_points 是一个包含固定点 TrajectoryID 的数组
filtered_fixed_points = fixed_points(ismember(fixed_points.TrajectoryID, unchanging_points), :);

% 固定点的数量
num_fixed_points = size(filtered_fixed_points, 1);

% 初始化存储固定点对应的匹配对
fixed_point_matches2 = cell(num_fixed_points, 1);

% 遍历每个固定点
for k = 1:num_fixed_points
    % 获取当前固定点的时间和时间容差
    fixed_time = table2array(filtered_fixed_points(k, 2));
    fixed_position = table2array(filtered_fixed_points(k, 3));
    
    % 初始化最小距离和对应的匹配对索引
    min_distance = inf;
    best_match_index = -1;
    
    % 遍历所有匹配对
    for m = 1:size(matched_pairs_info, 1)
        % 获取匹配对的两个点的时间、位置、速度和加速度信息
        time_A = matched_pairs_info.Time_A(m);
        time_B = matched_pairs_info.Time_B(m);
        position_A = matched_pairs_info.Position_A(m);
        position_B = matched_pairs_info.Position_B(m);
        speed_A = matched_pairs_info.Speed_A(m);
        speed_B = matched_pairs_info.Speed_B(m);
        acceleration_A = matched_pairs_info.Acceleration_A(m);
        acceleration_B = matched_pairs_info.Acceleration_B(m);
        
        % 检查固定点是否在匹配对的时间范围内
        if fixed_time >= min(time_A, time_B) && fixed_time <= max(time_A, time_B)
            if time_B ~= time_A% 使用线性插值法计算固定点的位置
                alpha = (fixed_time - time_A) / (time_B - time_A);
                interpolated_position = position_A + alpha * (position_B - position_A);

                % 计算固定点与插值位置的距离
                distance = abs(fixed_position - interpolated_position);
            else
                distance = abs(fixed_position);
            end
            
            % 如果距离小于当前最小距离，则更新最小距离和最佳匹配对索引
            if distance < min_distance
                min_distance = distance;
                best_match_index = m;
            end
        end
    end
    
    % 如果找到最佳匹配对，则记录该匹配对
    if best_match_index ~= -1
        fixed_point_matches2{k} = matched_pairs_info(best_match_index, :);
    else
        fixed_point_matches2{k} = [];
    end
end

% 显示固定点对应的匹配对
for k = 1:num_fixed_points
    if ~isempty(fixed_point_matches2{k})
        disp(['固定点 ', num2str(k), ' 对应的匹配对：']);
        disp(fixed_point_matches2{k});
    else
        disp(['固定点 ', num2str(k), ' 没有找到对应的匹配对']);
    end
end


% print('my_plot', '-dtiff', '-r300');
%%
% 假设 fixed_points 是一个 n x 2 的矩阵，每行表示一个固定点的 [时间, 位置]
% 假设 matched_pairs_info 是之前计算的匹配对信息表格
% 假设 fixed_points 是一个 n x 2 的矩阵，每行表示一个固定点的 [时间, 位置]
% 假设 matched_pairs_info 是之前计算的匹配对信息表格

% 固定检测点坐标，假设在 vehiclesInRangeAt50m1 中
fixed_points2 = vehiclesInRangeAt550m1;

% 筛选出 unchanging_points 对应的固定点
% 假设 unchanging_points 是一个包含固定点 TrajectoryID 的数组
filtered_fixed_points2 = fixed_points2(ismember(fixed_points2.TrajectoryID, unchanging_points), :);

% 固定点的数量
num_fixed_points = size(filtered_fixed_points2, 1);

% 初始化存储固定点对应的匹配对
fixed_point_matches2 = cell(num_fixed_points, 1);

% 存储计算出的比值
fixed_point_ratios2 = [];

% 遍历每个固定点
for k = 1:num_fixed_points
    % 获取当前固定点的时间和位置
    fixed_time = table2array(filtered_fixed_points2(k, 2));
    fixed_position = table2array(filtered_fixed_points2(k, 3));
    
    % 初始化最小距离和对应的匹配对索引
    min_distance = inf;
    best_match_index = -1;
    
    % 遍历所有匹配对
    for m = 1:size(matched_pairs_info, 1)
        % 获取匹配对的两个点的时间、位置、速度和加速度信息
        time_A = matched_pairs_info.Time_A(m);
        time_B = matched_pairs_info.Time_B(m);
        position_A = matched_pairs_info.Position_A(m);
        position_B = matched_pairs_info.Position_B(m);
        
        % 检查固定点是否在匹配对的时间范围内
        if fixed_time >= min(time_A, time_B) && fixed_time <= max(time_A, time_B)
            if time_B ~= time_A% 使用线性插值法计算固定点的位置
                alpha = (fixed_time - time_A) / (time_B - time_A);
                interpolated_position = position_A + alpha * (position_B - position_A);

                % 计算固定点与插值位置的距离
                distance = abs(fixed_position - interpolated_position);
            else
                distance = abs(fixed_position);
            end
            % 如果距离小于当前最小距离，则更新最小距离和最佳匹配对索引
            if distance < min_distance
                min_distance = distance;
                best_match_index = m;
            end
        end
    end
    
    % 如果找到最佳匹配对，则记录该匹配对
    if best_match_index ~= -1
         fixed_point_matches2{k} = matched_pairs_info(best_match_index, :);
         if fixed_point_matches2{k}.Time_A ~= fixed_point_matches2{k}.Time_B
            % 获取当前最佳匹配对的时间差和位置差
            tau_A = fixed_point_matches2{k}.Time_A - fixed_time;
            d_A = fixed_point_matches2{k}.Position_A - fixed_position;
            tau_B =  fixed_time - fixed_point_matches2{k}.Time_B;
            d_B =  fixed_position - fixed_point_matches2{k}.Position_B;

            % 计算时间差和位置差的比值
            ratio_tau_A = tau_A / (tau_A + tau_B);  % 时间差的比例
            ratio_d_A = d_A / (d_A + d_B);          % 位置差的比例

            % 存储计算出的比值
            fixed_point_ratios2 = [fixed_point_ratios2; ratio_tau_A, ratio_d_A];
        else
            % 获取当前最佳匹配对的时间差和位置差
            tau_A = fixed_point_matches2{k}.Time_A - fixed_time;
            d_A = fixed_point_matches2{k}.Position_A - fixed_position;
            tau_B =  fixed_time - fixed_point_matches2{k}.Time_B;
            d_B =  fixed_position - fixed_point_matches2{k}.Position_B;

            % 计算时间差和位置差的比值
            ratio_tau_A = 1;  % 时间差的比例
            ratio_d_A = d_A / (d_A + d_B);          % 位置差的比例

            % 存储计算出的比值
            fixed_point_ratios2 = [fixed_point_ratios2; ratio_tau_A, ratio_d_A];
        end
    else
        fixed_point_matches2{k} = [];
    end
end
fixed_point_ratios2(1, :) = [0, 0];  % 第一个固定点比值
fixed_point_ratios2(end, :) = [1, 1];  % 最后一个固定点比值


% 输出固定点的比值
disp('计算出的固定点比值：');
disp(fixed_point_ratios2);

%% 669
all_full_trajectories2 = {};  % 存储所有固定点的调整轨迹
% 参考轨迹 new_trajectory669
t_ref = new_trajectory669.Time; % 参考轨迹的时间
p_ref = new_trajectory669.Distance; % 参考轨迹的位置
speed_ref = new_trajectory669.Velocity; % 参考轨迹的速度
acc_ref = new_trajectory669.Acceleration; % 参考轨迹的加速度
% 参考轨迹 new_trajectory669
t_ref1 = new_trajectory505.Time; % 参考轨迹的时间
p_ref1 = new_trajectory505.Distance; % 参考轨迹的位置
% 筛选出 unchanging_points 对应的固定点
% 假设 unchanging_points 是一个包含固定点 TrajectoryID 的数组
filtered_fixed_points2 = fixed_points(ismember(fixed_points.TrajectoryID, unchanging_points), :);

figure;
% 遍历所有固定点
for k = 1:size(filtered_fixed_points2, 1)
    % 获取当前固定点的时间和位置
    fixed_time = table2array(filtered_fixed_points2(k, 2));
    fixed_position = table2array(filtered_fixed_points2(k, 3));
    
    % 获取当前固定点的比值
    ratio_tau_A = fixed_point_ratios2(k, 1);
    ratio_d_A = fixed_point_ratios2(k, 2);
    
    % 存储当前固定点的调整轨迹
    adjusted_trajectory_A = [];  % 每个固定点的轨迹A

    % 遍历所有匹配对数据
    for m = 1:size(matched_pairs_info, 1)
        % 获取当前匹配对的轨迹A和轨迹B的时间和位置
        time_A = matched_pairs_info.Time_A(m);
        position_A = matched_pairs_info.Position_A(m);
        time_B = matched_pairs_info.Time_B(m);
        position_B = matched_pairs_info.Position_B(m);
        speed_A = matched_pairs_info.Speed_A(m);
        acc_A = matched_pairs_info.Acceleration_A(m);
        
        % 计算轨迹A点的时间和位置的平移量
        time_shift_A = ratio_tau_A * (time_A - time_B);  % 时间差的平移量
        position_shift_A = ratio_d_A * (position_A - position_B);  % 位置差的平移量
        
        % 更新轨迹A的时间和位置
        adjusted_time_A = time_A - time_shift_A;
        adjusted_position_A = position_A - position_shift_A;

        % 将调整后的轨迹点添加到当前固定点的轨迹中
        adjusted_trajectory_A = [adjusted_trajectory_A; adjusted_time_A, adjusted_position_A, speed_A, acc_A];
    end
    
    % 存储当前固定点的调整轨迹
    all_full_trajectories2{k} = adjusted_trajectory_A;
    
    % 绘制调整后的轨迹 A
    plot(adjusted_trajectory_A(:, 1), adjusted_trajectory_A(:, 2), 'b-', 'DisplayName', ['Adjusted Trajectory A for Fixed Point ' num2str(k)]);
    hold on;
end

% 设置图例、标签和标题
% 可视化结果
plot(t_ref, p_ref, 'b-', 'LineWidth', 2); % 原始轨迹669
hold on;
plot(t_ref1, p_ref1, 'b-', 'LineWidth', 2); % 原始轨迹669
colors = lines(num_fixed_points); % 不同固定点的颜色
legend_entries = {'Trajectory 669'}; % 图例条目
for i = 1:num_fixed_points
    % 绘制固定点
    fixed_point_time = filtered_fixed_points2.Time(i);
    fixed_point_position = filtered_fixed_points2.Distance(i);
    plot(fixed_point_time, fixed_point_position, 'o', 'MarkerSize', 5, 'LineWidth', 1);
    % 添加图例条目
    legend_entries{end+1} = sprintf('Restored Trajectory %d', i);
    legend_entries{end+1} = sprintf('Fixed Point %d', i);
end

xlabel('Time');
ylabel('Position');
title('Original and Restored Trajectories for Multiple Fixed Points');
grid on;
hold off;

% 输出调整后的轨迹 A
disp('调整后的轨迹 A：');
disp(all_full_trajectories2);

