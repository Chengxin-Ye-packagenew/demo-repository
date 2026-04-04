% 初始化结果变量
lane_change_points = {}; % 用于存储换道点
% 初始化 common_times 为 cell 数组
common_times = cell(height(changing_points), 1);
best_lane_change_point_new=[];

% 假设 changing_points 的第一列是车辆ID，第二列是时间或其他信息
num_changing_points = size(changing_points, 1);

%% 第一个车道的changing_points
% 初始化结果数组
idx_changing = zeros(num_changing_points, 1);
changing_points_exact_time = zeros(num_changing_points, 1);
matched_cell_indices = zeros(num_changing_points, 1);  % 存储匹配到的cell索引

for i = 1:num_changing_points
    current_vehicle_id = changing_points(i, 1);
    found = false;
    
    % 遍历所有cell寻找匹配的车辆ID
    for l = 1:length(selected_trajectories1_new)
        % 检查当前cell的第一列是否包含该车辆ID
        if any(selected_trajectories1_new{l}(:,1) == current_vehicle_id)
            % 找到匹配的cell，记录索引位置
            % matching_indices = find(trajectory_cell1_ngsim{l}(:,1) == current_vehicle_id);
            matching_indices = find(selected_trajectories1_new{l}(:,1) == current_vehicle_id);
            idx_changing(i) = matching_indices(1);  
            % changing_points_exact_time(i) = selected_trajectories1_new{l}.globaltime(matching_indices(1));
            changing_points_exact_time(i) = selected_trajectories1_new{l}(matching_indices(1),2);
            matched_cell_indices(i) = l;  % 记录匹配到的cell索引
            found = true;
            break;  % 找到后跳出内层循环
        end
    end
    
    if ~found
        idx_changing(i) = NaN;
        changing_points_exact_time(i) = NaN;
        matched_cell_indices(i) = NaN;
        fprintf('警告: 未找到车辆ID %.0f 对应的轨迹数据\n', current_vehicle_id);
    end
end
% 加速度阈值（可以根据实际需求调整）
velocity_threshold = 0; % 设置加速度差的阈值
for i = 1:height(changing_points)
    if changing_points(i,2)==1
        changing_points_exact_time(i) = max(selected_trajectories1_new{matched_cell_indices(i)}(:,2));
        % changing_points_exact_time(i) = max(trajectory_cell1_ngsim{matched_cell_indices(i)}.globaltime);
        % changing_points_exact_dis (i) = max(trajectory_cell1_ngsim{matched_cell_indices(i)}.y);
         changing_points_exact_dis (i) = max(selected_trajectories1_new{matched_cell_indices(i)}(:,3));
        best_lane_change_point_new(i,1) =changing_points_exact_time (i);
        best_lane_change_point_new(i,2) =changing_points_exact_dis (i);
    else
        changing_points_exact_time(i) = min(selected_trajectories1_new{matched_cell_indices(i)}(:,2));
        % changing_points_exact_dis (i) = min(trajectory_cell1_ngsim{matched_cell_indices(i)}.y);
        changing_points_exact_dis (i) = min(selected_trajectories1_new{matched_cell_indices(i)}(:,3));
        best_lane_change_point_new(i,1) =changing_points_exact_time(i);
        best_lane_change_point_new(i,2) =changing_points_exact_dis (i);
    end
end

%% 第二个车道的changing_points
% 假设 changing_points 的第一列是车辆ID，第二列是时间或其他信息
num_changing_points2 = size(changing_points2, 1);

% 初始化结果数组
idx_changing2 = zeros(num_changing_points2, 1);
changing_points_exact_time2 = zeros(num_changing_points2, 1);
changing_points_exact_dis2 = zeros(num_changing_points2, 1);
matched_cell_indices2 = zeros(num_changing_points2, 1);  % 存储匹配到的cell索引
best_lane_change_point_new2 = zeros(num_changing_points2,2);
for i = 1:num_changing_points2
    current_vehicle_id = changing_points2(i, 1);
    found = false;
    
    % 遍历所有cell寻找匹配的车辆ID
    for l = 1:length(selected_trajectories2_new)
        % 检查当前cell的第一列是否包含该车辆ID
        if any(selected_trajectories2_new{l}(:,1) == current_vehicle_id)
            % 找到匹配的cell，记录索引位置
            matching_indices2 = find(selected_trajectories2_new{l}(:,1) == current_vehicle_id);
            idx_changing2(i) = matching_indices2(1);  
            changing_points_exact_time2(i) = selected_trajectories2_new{l}(matching_indices2(1),2);
            matched_cell_indices2(i) = l;  % 记录匹配到的cell索引
            found = true;
            break;  % 找到后跳出内层循环
        end
    end
    
    if ~found
        idx_changing2(i) = NaN;
        changing_points_exact_time2(i) = NaN;
        matched_cell_indices2(i) = NaN;
        fprintf('警告: 未找到车辆ID %.0f 对应的轨迹数据\n', current_vehicle_id);
    end
end
for i = 1:size(changing_points2,1)
    if changing_points2(i,2)==1
        changing_points_exact_time2 (i) = max(selected_trajectories2_new{matched_cell_indices2(i)}(:,2));
        changing_points_exact_dis2 (i) = max(selected_trajectories2_new{matched_cell_indices2(i)}(:,3));
        best_lane_change_point_new2(i,1) =changing_points_exact_time2 (i);
        best_lane_change_point_new2(i,2) =changing_points_exact_dis2 (i);
    elseif changing_points2(i,2)==2
        changing_points_exact_time2(i) = min(selected_trajectories2_new{matched_cell_indices2(i)}(:,2));
        changing_points_exact_dis2 (i) = min(selected_trajectories2_new{matched_cell_indices2(i)}(:,3));
        best_lane_change_point_new2(i,1) =changing_points_exact_time2 (i);
        best_lane_change_point_new2(i,2) =changing_points_exact_dis2 (i);
    end
end
%% 筛选最佳换道点
% 遍历 changing_points 数组
for i = 1:size(changing_points,1)
    % 获取 all_full_trajectories5 和 all_full_trajectories6 中的公共时间点
    % 计算公共时间序列
    time_min = min([min(all_full_trajectories9{i}(:,1)), min(all_full_trajectories10{i}(:,1))]);
    time_max = max([max(all_full_trajectories9{i}(:,1)), max(all_full_trajectories6{i}(:,1))]);

    % 按0.04秒间隔生成公共时间序列
    common_times{i} = (time_min:0.04:time_max)';
    current_common_times = common_times{i};
    % 假设 changing_points_exact_time2 是一个标量或者向量（长度与 current_common_times 相同）
    difference = current_common_times - changing_points_exact_time2(i);

    % 找到最小差值的索引
    [~, idx_changing(i)] = min(abs(difference));  % 取绝对值后找到最小差
end
%%
for i = 1:size(changing_points,1)
   current_common_times = common_times{i};
   lane_change_points = {};
    % 遍历所有公共时间点
    for t = 1:length( current_common_times)%idx_changing(i)
        % 获取当前公共时间点
        t_current = current_common_times(t);
        % 设置时间容差
        time_tolerance = 0.1;  % 根据您的时间精度调整

        % 找到轨迹5中最近的时间点
        time_diff1 = abs(all_full_trajectories5{i}(:,1) - t_current);
        [min_diff1, idx1] = min(time_diff1);
        if min_diff1 <= time_tolerance
        else
            idx1 = [];  % 未找到合适的时间点
        end

        % 找到轨迹6中最近的时间点
        time_diff2 = abs(all_full_trajectories6{i}(:,1) - t_current);
        [min_diff2, idx2] = min(time_diff2);
        if min_diff2 <= time_tolerance
            % 在容差范围内找到匹配点
        else
            idx2 = [];  % 未找到合适的时间点
        end

        if ~isempty(idx1) && ~isempty(idx2)
            % 获取轨迹5和轨迹6中对应的所有位置
            positions1 = all_full_trajectories5{i}(idx1, 2); % 车道1的所有空间点
            positions2 = all_full_trajectories6{i}(idx2, 2); % 车道2的所有空间点

            % 遍历轨迹5和轨迹6中所有的空间点对
            for u = 1:length(positions1)
                for j = 1:length(positions2)
                    
                    if i==1% 获取当前空间点对的空间区间
                    min_position = 0; % 取空间范围的最小值
                    max_position = 300; % 取空间范围的最大值
                    else
                    min_position = 0; % 取空间范围的最小值
                    max_position = 350; % 取空间范围的最大值
                    end

                    % 在这个区间内生成所有候选空间点
                    candidate_positions = min_position:1:max_position; % 生成候选点

                    % 遍历这些候选空间点
                    for k = 1:length(candidate_positions)
                        candidate_position = candidate_positions(k);

                        % 计算这个空间点的均值作为换道点
                        avg_position = candidate_position;

                        % 计算空间点的绝对差值并乘以0.5
                        space_diff = abs(positions1(u) - positions2(j)) * 0.5;

                        % 获取公共时间点对应的两个宏观基本图上的速度
                        [~, t_idx1] = min(abs(unique_t1_1007 - t_current)); % 找到最近的时间索引
                        [~, x_idx1] = min(abs(unique_x1_1007 - avg_position)); % 找到对应空间位置的索引
                        speed1 = result11_1007_new(t_idx1, x_idx1); % 获取车道1对应的速度

                        [~, t_idx2] = min(abs(unique_t2_1007 - t_current)); % 找到最近的时间索引
                        [~, x_idx2] = min(abs(unique_x2_1007 - avg_position)); % 找到对应空间位置的索引
                        speed2 = result21_1007_new(t_idx2, x_idx2); % 获取车道2对应的速度

                        % 计算这两个宏观基本图位置上的速度差值
                        velocity_diff = abs(speed1 - speed2);
                        % 如果加速度差超过阈值，跳过此点
                        if velocity_diff < velocity_threshold
                            continue;
                        end

                        % % 获取车道1和车道2的加速度（与速度调用逻辑相同）
                        % acceleration1 = result_new0831_11(t_idx1, x_idx1); % 获取车道1对应的加速度
                        % acceleration2 = result_new0831_21(t_idx2, x_idx2); % 获取车道2对应的加速度
                        %
                        % % 计算加速度差值
                        % acceleration_diff = abs(acceleration1 - acceleration2);


                        % 将计算的结果保存到换道点变量中
                        lane_change_points{end+1} = struct('time', t_current, 'avg_position', avg_position, ...
                            'space_diff', space_diff, 'velocity_diff', velocity_diff);%...
                        % 'acceleration_diff', acceleration_diff);
                    end
                end
            end
        end
    end

    % 遍历公共时间内所有时间点，筛选出最优换道点
    max_metric = -inf; % 初始化最大指标
    best_lane_change_point = []; % 最佳换道点

    for l = 1:length(lane_change_points)
        % 获取当前换道点的信息
        current_point = lane_change_points{l};
        metric = (current_point.velocity_diff)/current_point.space_diff; %+ current_point.acceleration_diff); % 综合指标，加入加速度差
            % 如果当前的比例指标更大，更新最佳换道点
            if metric > max_metric
                % if current_point.time> fixed_points_chang2(i,1)
                max_metric = metric;
                best_lane_change_point = current_point;
                % end
            end
    end

    % 输出最优换道点
    disp('最优换道点：');
    disp(best_lane_change_point);
    % 获取第一行和第二行数据
    first_row_data = best_lane_change_point.avg_position;
    second_row_data = best_lane_change_point.time;

    % 创建一个新的数组，将第一行和第二行数据作为列
    best_lane_change_point_new2(i,:) = [second_row_data,first_row_data];
    % 显示新数组
end
disp(best_lane_change_point_new2);

%% 在车道1的轨迹重构(上游/下游)
% 假设 fixed_points 是一个 n x 2 的矩阵，每行表示一个固定点的 [时间, 位置]
% 假设 matched_pairs_info 是之前计算的匹配对信息表格
fixed_points_chang = best_lane_change_point_new; % 固定检测点坐标  

% 筛选出 unchanging_points 对应的固定点
% 假设 unchanging_points 是一个包含固定点 TrajectoryID 的数组
filtered_fixed_points_2 = fixed_points_chang;

% 固定点的数量
num_fixed_points = size(filtered_fixed_points_2, 1);

% 初始化存储固定点对应的匹配对
fixed_point_matches = cell(num_fixed_points, 1);

% 遍历每个固定点
for k = 1:num_fixed_points
    % 获取当前固定点的时间和时间容差
    fixed_time = filtered_fixed_points_2(k, 1);
    fixed_position = filtered_fixed_points_2(k, 2);
    
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
            % 使用线性插值法计算固定点的位置
            alpha = (fixed_time - time_A) / (time_B - time_A);
            interpolated_position = position_A + alpha * (position_B - position_A);

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
        fixed_point_matches{k} = matched_pairs_info(best_match_index, :);
    else
        fixed_point_matches{k} = [];
    end
end

% 显示固定点对应的匹配对
for k = 1:num_fixed_points
    if ~isempty(fixed_point_matches{k})
        disp(['固定点 ', num2str(k), ' 对应的匹配对：']);
        disp(fixed_point_matches{k});
    else
        disp(['固定点 ', num2str(k), ' 没有找到对应的匹配对']);
    end
end


% print('my_plot', '-dtiff', '-r300');

% 假设 fixed_points 是一个 n x 2 的矩阵，每行表示一个固定点的 [时间, 位置]
% 假设 matched_pairs_info 是之前计算的匹配对信息表格
% 假设 fixed_points 是一个 n x 2 的矩阵，每行表示一个固定点的 [时间, 位置]
% 假设 matched_pairs_info 是之前计算的匹配对信息表格

% 固定检测点坐标，假设在 vehiclesInRangeAt50m1 中
fixed_points_chang =  best_lane_change_point_new;

% 筛选出 unchanging_points 对应的固定点
% 假设 unchanging_points 是一个包含固定点 TrajectoryID 的数组
filtered_fixed_points_2 = fixed_points_chang;

% 固定点的数量
num_fixed_points = size(filtered_fixed_points_2, 1);

% 初始化存储固定点对应的匹配对
fixed_point_matches = cell(num_fixed_points, 1);

% 存储计算出的比值
fixed_point_ratios = [];

% 遍历每个固定点
for k = 1:num_fixed_points
    % 获取当前固定点的时间和位置
    fixed_time = filtered_fixed_points_2(k, 1);
    fixed_position = filtered_fixed_points_2(k, 2);
    
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
            % 使用线性插值法计算固定点的位置
            alpha = (fixed_time - time_A) / (time_B - time_A);
            interpolated_position = position_A + alpha * (position_B - position_A);

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
        fixed_point_matches{k} = matched_pairs_info(best_match_index, :);
        if fixed_point_matches{k}.Time_A ~= fixed_point_matches{k}.Time_B
            % 获取当前最佳匹配对的时间差和位置差
            tau_A = fixed_point_matches{k}.Time_A - fixed_time;
            d_A = fixed_point_matches{k}.Position_A - fixed_position;
            tau_B =  fixed_time - fixed_point_matches{k}.Time_B;
            d_B =  fixed_position - fixed_point_matches{k}.Position_B;

            % 计算时间差和位置差的比值
            ratio_tau_A = tau_A / (tau_A + tau_B);  % 时间差的比例
            ratio_d_A = d_A / (d_A + d_B);          % 位置差的比例

            % 存储计算出的比值
            fixed_point_ratios = [fixed_point_ratios; ratio_tau_A, ratio_d_A];
        else
            % 获取当前最佳匹配对的时间差和位置差
            tau_A = fixed_point_matches{k}.Time_A - fixed_time;
            d_A = fixed_point_matches{k}.Position_A - fixed_position;
            tau_B =  fixed_time - fixed_point_matches{k}.Time_B;
            d_B =  fixed_position - fixed_point_matches{k}.Position_B;

            % 计算时间差和位置差的比值
            ratio_tau_A = 1;  % 时间差的比例
            ratio_d_A = d_A / (d_A + d_B);          % 位置差的比例

            % 存储计算出的比值
            fixed_point_ratios = [fixed_point_ratios; ratio_tau_A, ratio_d_A];
        end
    else
        fixed_point_matches{k} = [];
    end
end
% 输出固定点的比值
disp('计算出的固定点比值：');
disp(fixed_point_ratios);

%% 669
all_full_trajectories_5 = {};  % 存储所有固定点的调整轨迹
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
filtered_fixed_points_2 = fixed_points_chang;

figure;
% 遍历所有固定点
for k = 1:size(filtered_fixed_points_2, 1)
    % 获取当前固定点的时间和位置
    fixed_time = filtered_fixed_points_2(k, 1);
    fixed_position = filtered_fixed_points_2(k, 2);
    
    % 获取当前固定点的比值
    ratio_tau_A = fixed_point_ratios(k, 1);
    ratio_d_A = fixed_point_ratios(k, 2);
    
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
    all_full_trajectories_5{k} = adjusted_trajectory_A;
    
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
    fixed_point_time = filtered_fixed_points_2(i,1);
    fixed_point_position = filtered_fixed_points_2(i,2);
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
disp(all_full_trajectories_5);
%% 在车道1的轨迹重构2(上游/下游)
% 假设 fixed_points 是一个 n x 2 的矩阵，每行表示一个固定点的 [时间, 位置]
% 假设 matched_pairs_info 是之前计算的匹配对信息表格
fixed_points_chang2=[];
for i =1:size(changing_points,1)
    if changing_points(i,2) == 2
        fixed_points_chang2(i,1) = earliest_550_data1.Time(earliest_550_data1.TrajectoryID==changing_points(i,1));
        fixed_points_chang2(i,2) = earliest_550_data1.Distance(earliest_550_data1.TrajectoryID==changing_points(i,1));
    else
        fixed_points_chang2(i,1) = earliest_50_data1.Time(earliest_50_data1.TrajectoryID==changing_points(i,1));
        fixed_points_chang2(i,2) = earliest_50_data1.Distance(earliest_50_data1.TrajectoryID==changing_points(i,1));
    end
end


% 筛选出 unchanging_points 对应的固定点
% 假设 unchanging_points 是一个包含固定点 TrajectoryID 的数组
filtered_fixed_points_2 = fixed_points_chang2;

% 固定点的数量
num_fixed_points = size(filtered_fixed_points_2, 1);

% 初始化存储固定点对应的匹配对
fixed_point_matches = cell(num_fixed_points, 1);

% 遍历每个固定点
for k = 1:num_fixed_points
    % 获取当前固定点的时间和时间容差
    fixed_time = filtered_fixed_points_2(k, 1);
    fixed_position = filtered_fixed_points_2(k, 2);
    
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
        fixed_point_matches{k} = matched_pairs_info(best_match_index, :);
        if fixed_point_matches{k}.Time_A ~= fixed_point_matches{k}.Time_B
            % 获取当前最佳匹配对的时间差和位置差
            tau_A = fixed_point_matches{k}.Time_A - fixed_time;
            d_A = fixed_point_matches{k}.Position_A - fixed_position;
            tau_B =  fixed_time - fixed_point_matches{k}.Time_B;
            d_B =  fixed_position - fixed_point_matches{k}.Position_B;

            % 计算时间差和位置差的比值
            ratio_tau_A = tau_A / (tau_A + tau_B);  % 时间差的比例
            ratio_d_A = d_A / (d_A + d_B);          % 位置差的比例

            % 存储计算出的比值
            fixed_point_ratios = [fixed_point_ratios; ratio_tau_A, ratio_d_A];
        else
            % 获取当前最佳匹配对的时间差和位置差
            tau_A = fixed_point_matches{k}.Time_A - fixed_time;
            d_A = fixed_point_matches{k}.Position_A - fixed_position;
            tau_B =  fixed_time - fixed_point_matches{k}.Time_B;
            d_B =  fixed_position - fixed_point_matches{k}.Position_B;

            % 计算时间差和位置差的比值
            ratio_tau_A = 1;  % 时间差的比例
            ratio_d_A = d_A / (d_A + d_B);          % 位置差的比例

            % 存储计算出的比值
            fixed_point_ratios = [fixed_point_ratios; ratio_tau_A, ratio_d_A];
        end
    else
        fixed_point_matches{k} = [];
    end
end

% 显示固定点对应的匹配对
for k = 1:num_fixed_points
    if ~isempty(fixed_point_matches{k})
        disp(['固定点 ', num2str(k), ' 对应的匹配对：']);
        disp(fixed_point_matches{k});
    else
        disp(['固定点 ', num2str(k), ' 没有找到对应的匹配对']);
    end
end


% print('my_plot', '-dtiff', '-r300');

% 假设 fixed_points 是一个 n x 2 的矩阵，每行表示一个固定点的 [时间, 位置]
% 假设 matched_pairs_info 是之前计算的匹配对信息表格
% 假设 fixed_points 是一个 n x 2 的矩阵，每行表示一个固定点的 [时间, 位置]
% 假设 matched_pairs_info 是之前计算的匹配对信息表格


% 筛选出 unchanging_points 对应的固定点
% 假设 unchanging_points 是一个包含固定点 TrajectoryID 的数组
filtered_fixed_points_2 = fixed_points_chang2;

% 固定点的数量
num_fixed_points = size(filtered_fixed_points_2, 1);

% 初始化存储固定点对应的匹配对
fixed_point_matches = cell(num_fixed_points, 1);

% 存储计算出的比值
fixed_point_ratios = [];

% 遍历每个固定点
for k = 1:num_fixed_points
    % 获取当前固定点的时间和位置
    fixed_time = filtered_fixed_points_2(k, 1);
    fixed_position = filtered_fixed_points_2(k, 2);
    
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
            % 使用线性插值法计算固定点的位置
            alpha = (fixed_time - time_A) / (time_B - time_A);
            interpolated_position = position_A + alpha * (position_B - position_A);
            
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
        fixed_point_matches{k} = matched_pairs_info(best_match_index, :);

        if fixed_point_matches{k}.Time_A ~= fixed_point_matches{k}.Time_B
            % 获取当前最佳匹配对的时间差和位置差
            tau_A = fixed_point_matches{k}.Time_A - fixed_time;
            d_A = fixed_point_matches{k}.Position_A - fixed_position;
            tau_B =  fixed_time - fixed_point_matches{k}.Time_B;
            d_B =  fixed_position - fixed_point_matches{k}.Position_B;

            % 计算时间差和位置差的比值
            ratio_tau_A = tau_A / (tau_A + tau_B);  % 时间差的比例
            ratio_d_A = d_A / (d_A + d_B);          % 位置差的比例

            % 存储计算出的比值
            fixed_point_ratios = [fixed_point_ratios; ratio_tau_A, ratio_d_A];
        else
            % 获取当前最佳匹配对的时间差和位置差
            tau_A = fixed_point_matches{k}.Time_A - fixed_time;
            d_A = fixed_point_matches{k}.Position_A - fixed_position;
            tau_B =  fixed_time - fixed_point_matches{k}.Time_B;
            d_B =  fixed_position - fixed_point_matches{k}.Position_B;

            % 计算时间差和位置差的比值
            ratio_tau_A = 1;  % 时间差的比例
            ratio_d_A = d_A / (d_A + d_B);          % 位置差的比例

            % 存储计算出的比值
            fixed_point_ratios = [fixed_point_ratios; ratio_tau_A, ratio_d_A];
        end
    else
        fixed_point_matches{k} = [];
    end
end
% 输出固定点的比值
disp('计算出的固定点比值：');
disp(fixed_point_ratios);

%% 669
all_full_trajectories_6 = {};  % 存储所有固定点的调整轨迹
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
filtered_fixed_points_2 = fixed_points_chang2;

figure;
% 遍历所有固定点
for k = 4%1:size(filtered_fixed_points_2, 1)
    % 获取当前固定点的时间和位置
    fixed_time = filtered_fixed_points_2(k, 1);
    fixed_position = filtered_fixed_points_2(k, 2);
    
    % 获取当前固定点的比值
    ratio_tau_A = fixed_point_ratios(k, 1);
    ratio_d_A = fixed_point_ratios(k, 2);
    
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
    all_full_trajectories_6{k} = adjusted_trajectory_A;
    
    % 绘制调整后的轨迹 A
    plot(adjusted_trajectory_A(:, 1), adjusted_trajectory_A(:, 2),  'Color',[1, 0.5, 0], ...
            'LineWidth', 3, 'LineStyle', '--');
    hold on;
end
set(gca, 'XTick', [], 'YTick', []);  % 隐藏刻度线
set(gca, 'XLabel', [], 'YLabel', []);  % 隐藏坐标轴标签

% 设置图例、标签和标题
% 可视化结果
plot(t_ref, p_ref, 'g-', 'LineWidth', 3); % 原始轨迹669
hold on;
plot(t_ref1, p_ref1, 'g-', 'LineWidth', 3); % 原始轨迹669
colors = lines(num_fixed_points); % 不同固定点的颜色
legend_entries = {'Trajectory 669'}; % 图例条目
for i = 4%1:num_fixed_points
    % 绘制固定点
    fixed_point_time = filtered_fixed_points_2(i,1);
    fixed_point_position = filtered_fixed_points_2(i,2);
    plot(fixed_point_time, fixed_point_position, 'o', 'MarkerSize', 5, 'LineWidth', 1,'MarkerFaceColor', [1,0,0], ...
            'MarkerEdgeColor',[1,0,0]);
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
disp(all_full_trajectories_6);

%% 融合

% 假设 all_full_trajectories2 和 all_full_trajectories 是两个轨迹数据，包含 [时间, 位置] 列
% all_full_trajectories2 对应 550m 固定点计算重构的轨迹
% all_full_trajectories 对应 50m 固定点计算重构的轨迹

% 假设 unchanging_points 是一个包含车辆 ID 的数组

% 创建融合后的轨迹矩阵
all_fused_trajectories3 = {};

% 获取轨迹的总数量
num_trajectories = length(all_full_trajectories_5);

% 设置时间阈值为 0.5 秒
time_threshold = 0.5;

% 遍历 unchanging_points 中的每个车辆 ID
for k = 1:height(changing_points)
    
    % 获取当前车辆的 id
    vehicle_id = changing_points(k);
    
    % 获取对应的50m和550m轨迹数据
    idx_50m2 = find(vehiclesInRangeAt50m1.TrajectoryID == vehicle_id);
    idx_550m2 = find(vehiclesInRangeAt550m1.TrajectoryID == vehicle_id);
    if fixed_points_chang(k,1)>fixed_points_chang2(k,1)
        % 获取50m和550m轨迹的时间
        time_50m = fixed_points_chang2(k,1);
        time_550m = fixed_points_chang(k,1);

        % 获取50m和550m轨迹的数据
        trajectory_down = all_full_trajectories_6{k};  % 550m 固定点轨迹
        trajectory_up = all_full_trajectories_5{k};    % 50m 固定点轨迹
    else
        % 获取50m和550m轨迹的时间
        time_50m = fixed_points_chang(k,1);
        time_550m = fixed_points_chang2(k,1);

        % 获取50m和550m轨迹的数据
        trajectory_down = all_full_trajectories_5{k};  % 550m 固定点轨迹
        trajectory_up = all_full_trajectories_6{k};    % 50m 固定点轨迹
    end
    % 获取时间数据
    time_down = trajectory_down(:, 1);
    time_up = trajectory_up(:, 1);
    
    % 计算50m和550m之间的时间差
    time_diff = abs(time_550m - time_50m);
    
    % 创建一个空的矩阵来存储融合后的轨迹
    fused_trajectory = [];
    if changing_points(k,2) == 1
        % 当前时间t从50m固定点的时间开始，递增至550m固定点的时间
        t = min(time_down(1,1));  % 初始化t为50m固定点的时间
    else
        t=time_50m;

    end
    while time_50m >t 
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
        fused_position = pos_down(1,1);
        % 存储融合后的时间和位置
        fused_trajectory = [fused_trajectory; t, fused_position];
        % 增加时间（每次增加0.04秒）
        t = t + 0.04;
    end
    if changing_points(k,2) == 2
        % 当前时间t从50m固定点的时间开始，递增至550m固定点的时间
        t_end = min(time_up(end,1),time_down(end,1));  % 初始化t为50m固定点的时间
        ratio_tau_A=1;
    else
        t_end=time_550m;
        ratio_tau_A=0;
    end
    % 循环，直到t大于或等于550m的时间
    while (time_50m <=t )&&(t<= t_end)
       % 计算当前时间t和T
        t_relative = t - time_50m;  % 当前时间与50m时间的差值
        T = time_diff;              % 50m和550m之间的时间差
        
        % 计算时变融合比例 t/T
        % t_over_T = t_relative / T;
        % ratio_tau_A = t_over_T;
        
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
            fused_position = ratio_tau_A * pos_up(1,1) + (1 - ratio_tau_A) * pos_down(1,1);
        % elseif ~isnan(pos_down)  % 如果只有50m轨迹点有效
        %     fused_position = pos_down;
        % elseif ~isnan(pos_up)  % 如果只有550m轨迹点有效
        %     fused_position = pos_up;
        else
            fused_position = NaN;  % 如果两个点都无效
        end
        if fused_position>720
            break;
        end

        % 存储融合后的时间和位置
        fused_trajectory = [fused_trajectory; t, fused_position];
        
        % 增加时间（每次增加0.04秒）
        t = t + 0.04;
    end
     % % 扩展原始轨迹数据集  
        extended_input = fused_trajectory(:,1);
     % 以及设定了隐藏层大小和其他训练参数
        hiddenLayerSize = 10;
        trainRatio = 0.9;
        epochs = 100;
        goal = 1e-2;
        learningRate = 0.1;
     %    调用函数进行训练并得到结果
        [bp_net2, validationPerformance] = trainNeuralNetwork(fused_trajectory, hiddenLayerSize, trainRatio, epochs, goal, learningRate);

     %    使用BP神经网络预测扩展数据集的输出  
        fused_trajectory(:,2) = bp_net2(extended_input')';
    % 存储当前轨迹的融合结果
    all_fused_trajectories3{k} = fused_trajectory;
end

% 可视化融合后的轨迹
figure;
hold on;

% 绘制所有融合后的轨迹
for k = 4%1:num_trajectories
    plot(all_fused_trajectories3{k}(:, 1), all_fused_trajectories3{k}(:, 2), 'Color', 'b', ...
            'LineWidth', 3, 'LineStyle', '--');
end
set(gca, 'XTick', [], 'YTick', []);  % 隐藏刻度线
set(gca, 'XLabel', [], 'YLabel', []);  % 隐藏坐标轴标签

% 设置图例、标签和标题
% 可视化结果
plot(t_ref, p_ref, 'g-', 'LineWidth', 3); % 原始轨迹669
hold on;
plot(t_ref1, p_ref1, 'g-', 'LineWidth', 3); % 原始轨迹669
colors = lines(num_fixed_points); % 不同固定点的颜色
legend_entries = {'Trajectory 669'}; % 图例条目
for i = 4%1:num_fixed_points
    % 绘制固定点
    fixed_point_time = filtered_fixed_points_2(i,1);
    fixed_point_position = filtered_fixed_points_2(i,2);
    plot(fixed_point_time, fixed_point_position, 'o', 'MarkerSize', 5, 'LineWidth', 1,'MarkerFaceColor', [1,0,0], ...
            'MarkerEdgeColor',[1,0,0]);
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
disp(all_full_trajectories_6);

% 输出融合后的轨迹
disp('融合后的轨迹：');
disp(all_fused_trajectories3);

%% 在车道2的轨迹重构(上游/下游)
%% 在车道2的轨迹重构(上游/下游)
fixed_point_ratios=[];
% 假设 fixed_points 是一个 n x 2 的矩阵，每行表示一个固定点的 [时间, 位置]
% 假设 matched_pairs_info 是之前计算的匹配对信息表格
fixed_points_chang3 = best_lane_change_point_new2; % 固定检测点坐标  

% 筛选出 unchanging_points 对应的固定点
filtered_fixed_points_3 = fixed_points_chang3;

% 固定点的数量
num_fixed_points = size(filtered_fixed_points_3, 1);

% 初始化存储固定点对应的匹配对
fixed_point_matches = cell(num_fixed_points, 1);
% 遍历每个固定点
for k = 1:num_fixed_points
    % 获取当前固定点的时间和位置
    fixed_time = filtered_fixed_points_3(k, 1);
    fixed_position = filtered_fixed_points_3(k, 2);
    
    % 初始化最小距离和对应的匹配对索引
    min_distance = inf;
    best_match_index = -1;
    
    % 遍历所有匹配对
    for m = 1:size(matched_pairs_info2, 1)
        % 获取匹配对的两个点的时间、位置、速度和加速度信息
        time_A = matched_pairs_info2.Time_A(m);
        time_B = matched_pairs_info2.Time_B(m);
        position_A = matched_pairs_info2.Position_A(m);
        position_B = matched_pairs_info2.Position_B(m);
        
        % 检查固定点是否在匹配对的时间范围内
        if fixed_time >= min(time_A, time_B) && fixed_time <= max(time_A, time_B)
            % 使用线性插值法计算固定点的位置
            alpha = (fixed_time - time_A) / (time_B - time_A);
            interpolated_position = position_A + alpha * (position_B - position_A);
            
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
        fixed_point_matches{k} = matched_pairs_info2(best_match_index, :);
        
        % 获取当前最佳匹配对的时间差和位置差
        tau_A = fixed_point_matches{k}.Time_A - fixed_time;
        d_A = fixed_point_matches{k}.Position_A - fixed_position;
        tau_B =  fixed_time - fixed_point_matches{k}.Time_B;
        d_B =  fixed_position - fixed_point_matches{k}.Position_B;
        
        % 计算时间差和位置差的比值
        ratio_tau_A = tau_A / (tau_A + tau_B);  % 时间差的比例
        ratio_d_A = d_A / (d_A + d_B);          % 位置差的比例
        
 % 计算时间差和位置差的比值（避免除零错误）
        if (tau_A + tau_B) ~= 0
            ratio_tau_A = tau_A / (tau_A + tau_B);
        else
            ratio_tau_A = 1;
        end

        if (d_A + d_B) ~= 0
            ratio_d_A = d_A / (d_A + d_B);
        else
            ratio_d_A = 1;
        end

        % 存储计算出的比值
        fixed_point_ratios(k, :) = [ratio_tau_A, ratio_d_A];
    else
        fixed_point_matches{k} = [0.5,0.5];
    end
end
% 输出固定点的比值
disp('计算出的固定点比值：');
disp(fixed_point_ratios);

%% 初始化存储所有固定点的调整轨迹
all_full_trajectories_7 = cell(num_fixed_points, 1);

% 参考轨迹
t_ref = new_trajectory669_2.Time; % 参考轨迹的时间
p_ref = new_trajectory669_2.Distance; % 参考轨迹的位置
t_ref1 = new_trajectory505_2.Time; % 参考轨迹的时间
p_ref1 = new_trajectory505_2.Distance; % 参考轨迹的位置

figure;
hold on;

% 绘制参考轨迹
plot(t_ref, p_ref, 'k-', 'LineWidth', 2, 'DisplayName', 'Trajectory 669');
plot(t_ref1, p_ref1, 'k--', 'LineWidth', 2, 'DisplayName', 'Trajectory 505');

% 遍历所有固定点
for k = 1:num_fixed_points

        fixed_time = filtered_fixed_points_3(k, 1) ;
    fixed_position = filtered_fixed_points_3(k, 2);
    
    % 获取当前固定点的比值
    ratio_tau_A = fixed_point_ratios(k, 1);
    ratio_d_A = fixed_point_ratios(k, 2);
    
    % 存储当前固定点的调整轨迹
    adjusted_trajectory_A = [];
    
    % 遍历所有匹配对数据
    for m = 1:size(matched_pairs_info2, 1)
        % 获取当前匹配对的轨迹A和轨迹B的时间和位置
        time_A = matched_pairs_info2.Time_A(m);
        position_A = matched_pairs_info2.Position_A(m);
        time_B = matched_pairs_info2.Time_B(m);
        position_B = matched_pairs_info2.Position_B(m);
        
        % 计算轨迹A点的时间和位置的平移量
        time_shift_A = ratio_tau_A * (time_A - time_B);
        position_shift_A = ratio_d_A * (position_A - position_B);
        
        % 更新轨迹A的时间和位置
        adjusted_time_A = time_A - time_shift_A;
        adjusted_position_A = position_A - position_shift_A;
        
        % 将调整后的轨迹点添加到当前固定点的轨迹中
        adjusted_trajectory_A = [adjusted_trajectory_A; adjusted_time_A, adjusted_position_A];
    end
    
    % 对调整后的轨迹按时间排序
    if ~isempty(adjusted_trajectory_A)
        [sorted_times, sort_idx] = sort(adjusted_trajectory_A(:, 1));
        adjusted_trajectory_A = adjusted_trajectory_A(sort_idx, :);
    end
    
    % 存储当前固定点的调整轨迹
    all_full_trajectories_7{k} = adjusted_trajectory_A;
    
    % 绘制调整后的轨迹
    if ~isempty(adjusted_trajectory_A)
        plot(adjusted_trajectory_A(:, 1), adjusted_trajectory_A(:, 2), '-', ...
             'LineWidth', 1.5, 'DisplayName', ['Restored Trajectory ' num2str(k)]);
    end
    
    % 绘制固定点
    plot(fixed_time, fixed_position, 'o', 'MarkerSize', 8, 'LineWidth', 2, ...
         'DisplayName', ['Fixed Point ' num2str(k)]);
end

% 设置图例、标签和标题
xlabel('Time');
ylabel('Position');
title('Original and Restored Trajectories for Multiple Fixed Points');
legend('show', 'Location', 'best');
grid on;
hold off;

% 输出调整后的轨迹
disp('调整后的轨迹：');
for k = 1:num_fixed_points
    if ~isempty(all_full_trajectories_7{k})
        fprintf('固定点 %d 的轨迹有 %d 个点\n', k, size(all_full_trajectories_7{k}, 1));
    else
        fprintf('固定点 %d 的轨迹为空\n', k);
    end
end
%% 在车道2的轨迹重构2(上游/下游)
% 假设 fixed_points 是一个 n x 2 的矩阵，每行表示一个固定点的 [时间, 位置]
% 假设 matched_pairs_info 是之前计算的匹配对信息表格
fixed_points_chang4=[];
for i =1:height(changing_points2)
    if changing_points2(i,2) == 2
        fixed_points_chang4(i,1) = earliest_550_data2.Time(matched_cell_indices2(i));
        fixed_points_chang4(i,2) = earliest_550_data2.Distance(matched_cell_indices2(i));
    else
        fixed_points_chang4(i,1) = earliest_50_data2.Time(matched_cell_indices2(i));
        fixed_points_chang4(i,2) = earliest_50_data2.Distance(matched_cell_indices2(i));
    end
end


% 筛选出 unchanging_points 对应的固定点
% 假设 unchanging_points 是一个包含固定点 TrajectoryID 的数组
filtered_fixed_points_4 = fixed_points_chang4;

% 固定点的数量
num_fixed_points = size(filtered_fixed_points_4, 1);

% 初始化存储固定点对应的匹配对
fixed_point_matches = cell(num_fixed_points, 1);

% 遍历每个固定点
for k = 1:num_fixed_points
    % 获取当前固定点的时间和位置
    fixed_time = filtered_fixed_points_4(k, 1);
    fixed_position = filtered_fixed_points_4(k, 2);
    
    % 初始化最小距离和对应的匹配对索引
    min_distance = inf;
    best_match_index = -1;
    
    % 遍历所有匹配对
    for m = 1:size(matched_pairs_info2, 1)
        % 获取匹配对的两个点的时间、位置、速度和加速度信息
        time_A = matched_pairs_info2.Time_A(m);
        time_B = matched_pairs_info2.Time_B(m);
        position_A = matched_pairs_info2.Position_A(m);
        position_B = matched_pairs_info2.Position_B(m);
        
        % 检查固定点是否在匹配对的时间范围内
        if fixed_time >= min(time_A, time_B) && fixed_time <= max(time_A, time_B)
            % 使用线性插值法计算固定点的位置
            alpha = (fixed_time - time_A) / (time_B - time_A);
            interpolated_position = position_A + alpha * (position_B - position_A);
            
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
        fixed_point_matches{k} = matched_pairs_info2(best_match_index, :);
        
        % 获取当前最佳匹配对的时间差和位置差
        tau_A = fixed_point_matches{k}.Time_A - fixed_time;
        d_A = fixed_point_matches{k}.Position_A - fixed_position;
        tau_B =  fixed_time - fixed_point_matches{k}.Time_B;
        d_B =  fixed_position - fixed_point_matches{k}.Position_B;
        
        % 计算时间差和位置差的比值
        ratio_tau_A = tau_A / (tau_A + tau_B);  % 时间差的比例
        ratio_d_A = d_A / (d_A + d_B);          % 位置差的比例
        
 % 计算时间差和位置差的比值（避免除零错误）
        if (tau_A + tau_B) ~= 0
            ratio_tau_A = tau_A / (tau_A + tau_B);
        else
            ratio_tau_A = 1;
        end

        if (d_A + d_B) ~= 0
            ratio_d_A = d_A / (d_A + d_B);
        else
            ratio_d_A = 1;
        end

        % 存储计算出的比值
        fixed_point_ratios(k, :) = [ratio_tau_A, ratio_d_A];
    else
        fixed_point_matches{k} = [0.5,0.5];
    end
end
% 输出固定点的比值
disp('计算出的固定点比值：');
disp(fixed_point_ratios);

%% 669
all_full_trajectories_8 = {};  % 存储所有固定点的调整轨迹
% 参考轨迹 new_trajectory669
t_ref = new_trajectory669_2.Time; % 参考轨迹的时间
p_ref = new_trajectory669_2.Distance; % 参考轨迹的位置
speed_ref = new_trajectory669_2.Velocity; % 参考轨迹的速度
acc_ref = new_trajectory669_2.Acceleration; % 参考轨迹的加速度
% 参考轨迹 new_trajectory669
t_ref1 = new_trajectory505_2.Time; % 参考轨迹的时间
p_ref1 = new_trajectory505_2.Distance; % 参考轨迹的位置
% 筛选出 unchanging_points 对应的固定点
% 假设 unchanging_points 是一个包含固定点 TrajectoryID 的数组
filtered_fixed_points_4 = fixed_points_chang4;

figure;
% 遍历所有固定点
for k = 1:size(filtered_fixed_points_4, 1)
    % 获取当前固定点的时间和位置
    fixed_time = filtered_fixed_points_4(k, 1);
    fixed_position = filtered_fixed_points_4(k, 2);
    
    % 获取当前固定点的比值
    ratio_tau_A = fixed_point_ratios(k, 1);
    ratio_d_A = fixed_point_ratios(k, 2);
    
    % 存储当前固定点的调整轨迹
    adjusted_trajectory_A = [];  % 每个固定点的轨迹A

    % 遍历所有匹配对数据
    for m = 1:size(matched_pairs_info2, 1)
        % 获取当前匹配对的轨迹A和轨迹B的时间和位置
        time_A = matched_pairs_info2.Time_A(m);
        position_A = matched_pairs_info2.Position_A(m);
        time_B = matched_pairs_info2.Time_B(m);
        position_B = matched_pairs_info2.Position_B(m);
        speed_A = matched_pairs_info2.Speed_A(m);
        acc_A = matched_pairs_info2.Acceleration_A(m);
        
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
    all_full_trajectories_8{k} = adjusted_trajectory_A;
    
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
    fixed_point_time = filtered_fixed_points_4(i,1);
    fixed_point_position = filtered_fixed_points_4(i,2);
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
disp(all_full_trajectories_8);
%% 融合

% 假设 all_full_trajectories2 和 all_full_trajectories 是两个轨迹数据，包含 [时间, 位置] 列
% all_full_trajectories2 对应 550m 固定点计算重构的轨迹
% all_full_trajectories 对应 50m 固定点计算重构的轨迹

% 假设 unchanging_points 是一个包含车辆 ID 的数组

% 创建融合后的轨迹矩阵
all_fused_trajectories4 = {};

% 获取轨迹的总数量
num_trajectories = length(all_full_trajectories_8);

% 设置时间阈值为 0.5 秒
time_threshold = 5;
% 遍历 unchanging_points 中的每个车辆 ID
for k = 1:height(changing_points2)
    
    % 获取当前车辆的 id
    vehicle_id = changing_points2(k);
    
    % 获取对应的50m和550m轨迹数据
    idx_50m2 = find(vehiclesInRangeAt50m2.TrajectoryID == vehicle_id);
    idx_550m2 = find(vehiclesInRangeAt550m2.TrajectoryID == vehicle_id);
    if fixed_points_chang3(k,1)>fixed_points_chang4(k,1)
        % 获取50m和550m轨迹的时间
        time_50m2 = fixed_points_chang4(k,1);
        time_550m2 = fixed_points_chang3(k,1);

        % 获取50m和550m轨迹的数据
        trajectory_down2 = all_full_trajectories_8{k};  % 550m 固定点轨迹
        trajectory_up2 = all_full_trajectories_7{k};    % 50m 固定点轨迹
    else
        % 获取50m和550m轨迹的时间
        time_50m2 = fixed_points_chang3(k,1);
        time_550m2 = fixed_points_chang4(k,1);

        % 获取50m和550m轨迹的数据
        trajectory_down2 = all_full_trajectories_7{k};  % 550m 固定点轨迹
        trajectory_up2 = all_full_trajectories_8{k};    % 50m 固定点轨迹
    end
    % 获取时间数据
    time_down2 = trajectory_down2(:, 1);
    time_up2 = trajectory_up2(:, 1);
    
    % 计算50m和550m之间的时间差
    time_diff2 = abs(time_550m2 - time_50m2);
    
    % 创建一个空的矩阵来存储融合后的轨迹
    fused_trajectory2 = [];
    if changing_points2(k,2) == 1
        % 当前时间t从50m固定点的时间开始，递增至550m固定点的时间
        t = min(time_down2(1,1));  % 初始化t为50m固定点的时间
    else
        t=time_50m2;
    end
    while time_50m2 >t 
         % 获取当前时间对应的轨迹位置
        % 如果t在50m轨迹中存在
        if ismember(t, time_down2)
            pos_down = trajectory_down2(time_down2 == t, 2);  % 50m轨迹的位置
        else
            % 找到与当前时间最接近的时间点并取位置
            [~, idx] = min(abs(time_down2 - t));  
            % 如果时间差大于阈值则跳过此点，不进行融合
            if abs(time_down2(idx) - t) > time_threshold
                pos_down = NaN;  % 设置为NaN表示该点无法融合
            else
                pos_down = trajectory_down2(idx, 2); % 取最接近的点的位置
            end
        end
        fused_position = pos_down(1,1);
        % 存储融合后的时间和位置
        fused_trajectory2 = [fused_trajectory2; t, fused_position];
        % 增加时间（每次增加0.04秒）
        t = t + 0.04;
    end
    if changing_points2(k,2) == 2
        % 当前时间t从50m固定点的时间开始，递增至550m固定点的时间
        t_end = min(time_up2(end,1),time_down2(end,1));  % 初始化t为50m固定点的时间
        ratio_tau_A=1;
    else
        t_end=time_550m2;
        ratio_tau_A=0;
    end
    % 循环，直到t大于或等于550m的时间
    while (time_50m2 <= t )&&(t<= t_end)
       % 计算当前时间t和T
        t_relative = t - time_50m2;  % 当前时间与50m时间的差值
        T = time_diff2;              % 50m和550m之间的时间差
        
        % % 计算时变融合比例 t/T
        % t_over_T = t_relative / T;
        % ratio_tau_A = t_over_T;
        
        % 获取当前时间对应的轨迹位置
        % 如果t在50m轨迹中存在
        if ismember(t, time_down2)
            pos_down = trajectory_down2(time_down2 == t, 2);  % 50m轨迹的位置
        else
            % 找到与当前时间最接近的时间点并取位置
            [~, idx] = min(abs(time_down2 - t));  
            % 如果时间差大于阈值则跳过此点，不进行融合
            if abs(time_down2(idx) - t) > time_threshold
                pos_down = NaN;  % 设置为NaN表示该点无法融合
            else
                pos_down = trajectory_down2(idx, 2); % 取最接近的点的位置
            end
        end
        
        % 如果t在550m轨迹中存在
        if ismember(t, time_up2)
            pos_up = trajectory_up2(time_up2 == t, 2);  % 550m轨迹的位置
        else
            % 找到与当前时间最接近的时间点并取位置
            [~, idx] = min(abs(time_up2 - t));  
            % 如果时间差大于阈值则跳过此点，不进行融合
            if abs(time_up2(idx) - t) > time_threshold
                pos_up = NaN;  % 设置为NaN表示该点无法融合
            else
                pos_up = trajectory_up2(idx, 2); % 取最接近的点的位置
            end
        end
        
        % 如果两个轨迹点都有效（即都没有超过阈值）
        if all(~isnan(pos_down)) && all(~isnan(pos_up))
            % 使用时变融合方程进行融合
            fused_position = ratio_tau_A * pos_up(1,1) + (1 - ratio_tau_A) * pos_down(1,1);
        % elseif ~isnan(pos_down)  % 如果只有50m轨迹点有效
        %     fused_position = pos_down;
        % elseif ~isnan(pos_up)  % 如果只有550m轨迹点有效
        %     fused_position = pos_up;
        else
            fused_position = NaN;  % 如果两个点都无效
        end
        if fused_position >720
            break
        end
        fused_trajectory2 = [fused_trajectory2; t, fused_position];
                 % % 扩展原始轨迹数据集  
       
        % 存储融合后的时间和位置
        % 增加时间（每次增加0.04秒）
        t = t + 0.1;
    end
     extended_input = fused_trajectory2(:,1);
     % 以及设定了隐藏层大小和其他训练参数
        hiddenLayerSize = 10;
        trainRatio = 0.9;
        epochs = 100;
        goal = 1e-2;
        learningRate = 0.1;
     %    调用函数进行训练并得到结果
        [bp_net2, validationPerformance] = trainNeuralNetwork(fused_trajectory2, hiddenLayerSize, trainRatio, epochs, goal, learningRate);

     %    使用BP神经网络预测扩展数据集的输出  
        fused_trajectory2(:,2) = bp_net2(extended_input')';
    % 存储当前轨迹的融合结果
    all_fused_trajectories4{k} = fused_trajectory2;
end

% 可视化融合后的轨迹
figure;
hold on;

% 绘制所有融合后的轨迹
for k = 1:num_trajectories
    if ~isempty(all_fused_trajectories4{k})
        plot(all_fused_trajectories4{k}(:, 1), all_fused_trajectories4{k}(:, 2), 'DisplayName', ['Fused Trajectory ' num2str(k)]);
    end
end

% 添加图例和标签
legend show;
xlabel('时间');
ylabel('位置');
title('融合后的轨迹');

hold off;

% 输出融合后的轨迹
disp('融合后的轨迹：');
for k = 1:num_trajectories
    if ~isempty(all_fused_trajectories4{k})
        fprintf('轨迹 %d: %d 个点\n', k, size(all_fused_trajectories4{k}, 1));
    else
        fprintf('轨迹 %d: 空\n', k);
    end
end
%%
% 假设 all_fused_trajectories4 和 all_fused_trajectories2 是 cell 格式，每个 cell 存储一个轨迹

% 1. 提取每个轨迹的第一行第一列值
% 提取 all_fused_trajectories4 和 all_fused_trajectories2 中每个轨迹的第一行第一列
first_column_4 = cellfun(@(x) x(1, 1), all_fused_trajectories4);  % all_fused_trajectories4 第一列的值
first_column_2 = cellfun(@(x) x(1, 1), all_fused_trajectories2);  % all_fused_trajectories2 第一列的值

% 2. 对轨迹进行排序
% 按照第一列值进行排序
[~, idx_sorted_4] = sort(first_column_4);  % 排序 all_fused_trajectories4 的索引
[~, idx_sorted_2] = sort(first_column_2);  % 排序 all_fused_trajectories2 的索引

% 对 all_fused_trajectories4 和 all_fused_trajectories2 进行排序
sorted_trajectories_4 = all_fused_trajectories4(idx_sorted_4);
sorted_trajectories_2 = all_fused_trajectories2(idx_sorted_2);

% 3. 合并两个已经排序的 cell 数组
% 将 sorted_trajectories_4 插入到 sorted_trajectories_2 中
% 按照第一列的大小顺序合并
all_fused_trajectories2_merged = cell(1, numel(sorted_trajectories_4) + numel(sorted_trajectories_2));

i_4 = 1; % all_fused_trajectories4 的索引
i_2 = 1; % all_fused_trajectories2 的索引
for i = 1:numel(all_fused_trajectories2_merged)
    if i_4 <= numel(sorted_trajectories_4) && (i_2 > numel(sorted_trajectories_2) || first_column_4(idx_sorted_4(i_4)) < first_column_2(idx_sorted_2(i_2)))
        % 如果 all_fused_trajectories4 中当前元素小于 all_fused_trajectories2 中当前元素
        all_fused_trajectories2_merged{i} = sorted_trajectories_4{i_4};
        i_4 = i_4 + 1;  % 移动到下一个元素
    else
        % 否则，取 all_fused_trajectories2 中的元素
        all_fused_trajectories2_merged{i} = sorted_trajectories_2{i_2};
        i_2 = i_2 + 1;  % 移动到下一个元素
    end
end

% 现在 all_fused_trajectories2_merged 是按第一行第一列值排序后的合并结果
%%
% 假设 all_fused_trajectories3 和 all_fused_trajectories 是 cell 格式，每个 cell 存储一个轨迹

% 1. 提取每个轨迹的第一行第一列值
% 提取 all_fused_trajectories3 和 all_fused_trajectories 中每个轨迹的第一行第一列
first_column_3 = cellfun(@(x) x(1, 1), all_fused_trajectories3);  % all_fused_trajectories3 第一列的值
first_column = cellfun(@(x) x(1, 1), all_fused_trajectories);  % all_fused_trajectories 第一列的值

% 2. 对轨迹进行排序
% 按照第一列值进行排序
[~, idx_sorted_3] = sort(first_column_3);  % 排序 all_fused_trajectories3 的索引
[~, idx_sorted] = sort(first_column);  % 排序 all_fused_trajectories 的索引

% 对 all_fused_trajectories3 和 all_fused_trajectories 进行排序
sorted_trajectories_3 = all_fused_trajectories3(idx_sorted_3);
sorted_trajectories = all_fused_trajectories(idx_sorted);

% 3. 合并两个已经排序的 cell 数组
% 将 sorted_trajectories_3 插入到 sorted_trajectories 中
% 按照第一列的大小顺序合并
all_fused_trajectories_merged = cell(1, numel(sorted_trajectories_3) + numel(sorted_trajectories));

i_3 = 1; % all_fused_trajectories3 的索引
i = 1; % all_fused_trajectories 的索引
for i_merged = 1:numel(all_fused_trajectories_merged)
    if i_3 <= numel(sorted_trajectories_3) && (i > numel(sorted_trajectories) || first_column_3(idx_sorted_3(i_3)) < first_column(idx_sorted(i)))
        % 如果 all_fused_trajectories3 中当前元素小于 all_fused_trajectories 中当前元素
        all_fused_trajectories_merged{i_merged} = sorted_trajectories_3{i_3};
        i_3 = i_3 + 1;  % 移动到下一个元素
    else
        % 否则，取 all_fused_trajectories 中的元素
        all_fused_trajectories_merged{i_merged} = sorted_trajectories{i};
        i = i + 1;  % 移动到下一个元素
    end
end

% 现在 all_fused_trajectories_merged 是按第一行第一列值排序后的合并结果
