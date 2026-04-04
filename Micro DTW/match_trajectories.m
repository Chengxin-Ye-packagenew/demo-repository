function [global_path_sorted, global_path,tau, d,tA,pA,tB,pB] = match_trajectories(trajA, trajB, low_speed_threshold, min_consecutive_points)

    tA = trajA.Time;   % 轨迹A的时间
    pA = trajA.Distance; % 轨迹A的位置
    speedA = trajA.Velocity; % 轨迹A的速度

    tB = trajB.Time;   % 轨迹B的时间
    pB = trajB.Distance; % 轨迹B的位置
    speedB = trajB.Velocity; % 轨迹B的速度

    % 找到低速区域，speedA 和 speedB 是低于阈值的点
    low_speed_A_indices = find(speedA < low_speed_threshold);
    low_speed_B_indices = find(speedB < low_speed_threshold);

    % 对于 A 轨迹：确保至少有50个连续的低速点
    regionsA = [];
    if ~isempty(low_speed_A_indices)
        % 计算相邻点的差值
        diff_A = diff(low_speed_A_indices);  % 索引差值
        
        % 通过差值找到不连续的点，标记为新的低速区域
        breakpoints_A = find(diff_A > 1);  % 不连续的点

        % 添加开始和结束点
        start_idx = 1;  % 默认开始索引
        for i = 1:length(breakpoints_A)
            % 当前区域的结束索引
            end_idx = breakpoints_A(i);
            % 当前区域的长度
            if end_idx - start_idx + 1 >= min_consecutive_points
                % 如果该区域的长度大于设定的阈值，加入到regionsA
                regionsA = [regionsA; low_speed_A_indices(start_idx), low_speed_A_indices(end_idx)];
            end
            % 更新下一个区域的起始点
            start_idx = breakpoints_A(i) + 1;
        end
        % 处理最后一个区域
        if length(low_speed_A_indices) - start_idx + 1 >= min_consecutive_points
            regionsA = [regionsA; low_speed_A_indices(start_idx), low_speed_A_indices(end)];
        end
    end

    % 对于 B 轨迹：确保至少有50个连续的低速点
    regionsB = [];
    if ~isempty(low_speed_B_indices)
        % 计算相邻点的差值
        diff_B = diff(low_speed_B_indices);  % 索引差值
        
        % 通过差值找到不连续的点，标记为新的低速区域
        breakpoints_B = find(diff_B > 1);  % 不连续的点

        % 添加开始和结束点
        start_idx = 1;  % 默认开始索引
        for i = 1:length(breakpoints_B)
            % 当前区域的结束索引
            end_idx = breakpoints_B(i);
            % 当前区域的长度
            if end_idx - start_idx + 1 >= min_consecutive_points
                % 如果该区域的长度大于设定的阈值，加入到regionsB
                regionsB = [regionsB; low_speed_B_indices(start_idx), low_speed_B_indices(end_idx)];
            end
            % 更新下一个区域的起始点
            start_idx = breakpoints_B(i) + 1;
        end
        % 处理最后一个区域
        if length(low_speed_B_indices) - start_idx + 1 >= min_consecutive_points
            regionsB = [regionsB; low_speed_B_indices(start_idx), low_speed_B_indices(end)];
        end
    end
    global_path=[];
    % 如果没有低速区域，则直接进行常规的DTW匹配
    if isempty(regionsA) && isempty(regionsB)
        % 没有低速区域，直接进行常规的DTW匹配
        [global_path, ~] = dtw_core(speedA, speedB, 'a2b');
    else
        % 如果有低速区域，进行低速区域的匹配
        if isempty(regionsA) && ~isempty(regionsB)
            % 只有trajB有低速区域，找到与trajA的交点进行匹配
            mid_point_B = round((regionsB(1) + regionsB(end)) / 2); % 计算B轨迹低速区域的中点
            slope = -4.08;  % 示例斜率，可以根据实际需求调整
            intercept = pB(mid_point_B) - slope * tB(mid_point_B);
            intersection_tA = (pA - intercept) / slope;
            [~, closest_idx] = min(abs(tA - intersection_tA));  % 找到与trajA最接近的点
            low_speed_A_start = closest_idx; % 设定trajA的低速区起点
            low_speed_A_end = low_speed_A_start; % 单点匹配

            % 使用DTW匹配低速区域
            [sub_path, ~] = dtw_core(speedA(low_speed_A_start:low_speed_A_end), speedB(regionsB(1):regionsB(end)), 'a2b');
            sub_path(:, 1) = sub_path(:, 1) + low_speed_A_start - 1;
            sub_path(:, 2) = sub_path(:, 2) + regionsB(1) - 1;
            global_path = [global_path;sub_path];
        elseif ~isempty(regionsA) && isempty(regionsB)
            % 只有trajA有低速区域，找到与trajB的交点进行匹配
            mid_point_A = round((regionsA(1) + regionsA(end)) / 2);
            slope = -3.08;  % 示例斜率
            intercept = pA(mid_point_A) - slope * tA(mid_point_A);
            intersection_tB = (pB - intercept) / slope;
            [~, closest_idx] = min(abs(tB - intersection_tB));  % 找到与trajB最接近的点
            low_speed_B_start = closest_idx; % 设定trajB的低速区起点
            low_speed_B_end = low_speed_B_start; % 单点匹配

            % 使用DTW匹配低速区域
            [sub_path, ~] = dtw_core(speedA(regionsA(1):regionsA(end)), speedB(low_speed_B_start:low_speed_B_end), 'b2a');
            sub_path(:, 1) = sub_path(:, 1) + regionsA(1) - 1;
            sub_path(:, 2) = sub_path(:, 2) + low_speed_B_start - 1;
            global_path = [global_path;sub_path];

        elseif ~isempty(regionsA) && ~isempty(regionsB)
            % 初始化标记变量，表示哪些低速区域已匹配
            matched_A = false(size(regionsA, 1), 1);
            matched_B = false(size(regionsB, 1), 1);

            % 逐对遍历A和B的低速区域
            for i = 1:size(regionsA, 1)
                for j = 1:size(regionsB, 1)
                    % 如果当前A和B的低速区域都还没有被匹配
                    if ~matched_A(i) && ~matched_B(j)
                        % 检查A和B的低速区域的时间和空间条件
                        if pA(regionsA(i, 1)) > pB(regionsB(j, 1)) && tA(regionsA(i, 1)) < tB(regionsB(j, 1))
                            % 匹配A和B的低速区域
                            [sub_path, ~] = dtw_core(speedA(regionsA(i, 1):regionsA(i, end)), speedB(regionsB(j, 1):regionsB(j, end)), 'a2b');
                            sub_path(:, 1) = sub_path(:, 1) + regionsA(i, 1) - 1;  % 还原索引
                            sub_path(:, 2) = sub_path(:, 2) + regionsB(j, 1) - 1;  % 还原索引
                             global_path = [global_path;sub_path];
                            % 标记这些区域已匹配
                            matched_A(i) = true;
                            matched_B(j) = true;
                            break;  % 找到匹配对后跳出
                        end
                    end
                end
            end

            % 对于剩余没有匹配的低速区域，进行交点匹配
            for i = 1:size(regionsA, 1)
                if ~matched_A(i)
                    % 匹配A的低速区域找到与B的交点进行匹配
                    mid_point_A = round((regionsA(i, 1) + regionsA(i, end)) / 2); % 计算A轨迹低速区域的中点
                    slope = -7.18;  % 示例斜率
                    intercept = pA(mid_point_A) - slope * tA(mid_point_A);
                    intersection_tB = (pB - intercept) / slope;  % 计算与B轨迹的交点
                    [~, closest_idx_B] = min(abs(tB - intersection_tB));  % 找到与B轨迹最接近的点
                    low_speed_B_start = closest_idx_B; % 设定B轨迹低速区起点
                    low_speed_B_end = low_speed_B_start; % 单点匹配

                    % 使用DTW匹配A的低速区域与B的交点
                    [sub_path, ~] = dtw_core(speedA(regionsA(i, 1):regionsA(i, end)), speedB(low_speed_B_start:low_speed_B_end), 'a2b');
                    sub_path(:, 1) = sub_path(:, 1) + regionsA(i, 1) - 1;  % 还原索引
                    sub_path(:, 2) = sub_path(:, 2) + low_speed_B_start - 1;  % 还原索引
                    global_path = [global_path;sub_path];

                    % 标记该A区域已匹配
                    matched_A(i) = true;
                end
            end

            for j = 1:size(regionsB, 1)
                if ~matched_B(j)
                    slope = -7.18; 
                    % 匹配B的低速区域找到与A的交点进行匹配
                    mid_point_B = round((regionsB(j, 1) + regionsB(j, end)) / 2); % 计算B轨迹低速区域的中点
                    intercept = pB(mid_point_B) - slope * tB(mid_point_B);
                    intersection_tA = (pA - intercept) / slope;  % 计算与A轨迹的交点
                    [~, closest_idx_A] = min(abs(tA - intersection_tA));  % 找到与A轨迹最接近的点
                    low_speed_A_start = closest_idx_A; % 设定A轨迹低速区起点
                    low_speed_A_end = low_speed_A_start; % 单点匹配

                    % 使用DTW匹配B的低速区域与A的交点
                    [sub_path_B, ~] = dtw_core(speedA(low_speed_A_start:low_speed_A_end), speedB(regionsB(j, 1):regionsB(j, end)), 'b2a');
                    sub_path_B(:, 1) = sub_path_B(:, 1) + low_speed_A_start - 1;  % 还原索引
                    sub_path_B(:, 2) = sub_path_B(:, 2) + regionsB(j, 1) - 1;  % 还原索引

                    % 合并路径时，确保统一索引空间
                    global_path = [global_path;sub_path_B];

                    % 标记该B区域已匹配
                    matched_B(j) = true;
                end
            end

        end
    end

    % % 阶段2：匹配剩余区域（防止交叉匹配）
    matched_A = false(size(tA));
    matched_B = false(size(tB));
    if ~isempty(global_path)
        matched_A(global_path(:, 1)) = true;
        matched_B(global_path(:, 2)) = true;
    end

    % 获取未匹配区域
    unmatched_A = find(~matched_A);
    unmatched_B = find(~matched_B);

    % 防止交叉匹配的核心逻辑：逐对匹配时，确保顺序不会交叉
    global_path_sorted = sortrows(global_path, 1);  % 按A轨迹时间排序，确保顺序

    % 假设tA和tB是待匹配的轨迹数据



    % 对A轨迹的未匹配点进行处理（防止交叉匹配）
    for i = 1:length(unmatched_A)
        current_idx_A = unmatched_A(i);  % A轨迹中的未匹配点

        % 找到A轨迹上当前点的前一个已匹配点和下一个已匹配点
        prev_matched_idx = find(global_path_sorted(:, 1) < current_idx_A, 1, 'last');
        next_matched_idx = find(global_path_sorted(:, 1) > current_idx_A, 1, 'first');

        % 候选匹配点：包括A和B未匹配点之间的配对
        candidates = [];
        if ~isempty(prev_matched_idx)
            candidates = [candidates; global_path_sorted(prev_matched_idx, 2)];
        end
        if ~isempty(next_matched_idx)
            candidates = [candidates; global_path_sorted(next_matched_idx, 2)];
        end

        % 考虑B的未匹配点，也作为候选项
        for j = 1:length(unmatched_B)
            if ~ismember(unmatched_B(j), candidates)  % 确保B的未匹配点不重复
                candidates = [candidates; unmatched_B(j)];
            end
        end

        best_match_B = [];
        min_diff = Inf;

        % 选择最合适的匹配B点
        for j = 1:length(candidates)
            candidate_B = candidates(j);

            % 检查是否会发生交叉
            cross_flag = false;
            for k = 1:size(global_path_sorted, 1)
                if (global_path_sorted(k, 1) < current_idx_A && global_path_sorted(k, 2) > candidate_B) || ...
                   (global_path_sorted(k, 1) > current_idx_A && global_path_sorted(k, 2) < candidate_B)
                    cross_flag = true;
                    break;
                end
            end

            % 如果没有交叉，选择时间差最小的匹配点
            if ~cross_flag
                time_diff = abs(tA(current_idx_A) - tB(candidate_B));
                if time_diff < min_diff
                    min_diff = time_diff;
                    best_match_B = candidate_B;
                end
            end
        end


        % 如果找到最佳匹配，加入匹配路径
        if ~isempty(best_match_B)
            global_path_sorted = [global_path_sorted; current_idx_A, best_match_B];
            global_path_sorted = sortrows(global_path_sorted, 1); % 保证排序
        end
    end

    % 对B轨迹的未匹配点进行处理（防止交叉匹配）
    for j = 1:length(unmatched_B)
        current_idx_B = unmatched_B(j);  % B轨迹中的未匹配点

        % 找到B轨迹上当前点的前一个已匹配点和下一个已匹配点
        prev_matched_idx = find(global_path_sorted(:, 2) < current_idx_B, 1, 'last');
        next_matched_idx = find(global_path_sorted(:, 2) > current_idx_B, 1, 'first');

        % 候选匹配点：包括A和B未匹配点之间的配对
        candidates = [];
        if ~isempty(prev_matched_idx)
            candidates = [candidates; global_path_sorted(prev_matched_idx, 1)];
        end
        if ~isempty(next_matched_idx)
            candidates = [candidates; global_path_sorted(next_matched_idx, 1)];
        end

        % 考虑A的未匹配点，也作为候选项
        for i = 1:length(unmatched_A)
            if ~ismember(unmatched_A(i), candidates)  % 确保A的未匹配点不重复
                candidates = [candidates; unmatched_A(i)];
            end
        end

        best_match_A = [];
        min_diff = Inf;

        % 选择最合适的匹配A点
        for k = 1:length(candidates)
            candidate_A = candidates(k);

            % 检查是否会发生交叉
            cross_flag = false;
            for m = 1:size(global_path_sorted, 1)
                if (global_path_sorted(m, 1) < candidate_A && global_path_sorted(m, 2) > current_idx_B) || ...
                   (global_path_sorted(m, 1) > candidate_A && global_path_sorted(m, 2) < current_idx_B)
                    cross_flag = true;
                    break;
                end
            end

            % 如果没有交叉，选择时间差最小的匹配点
            if ~cross_flag
                time_diff = abs(tB(current_idx_B) - tA(candidate_A));
                if time_diff < min_diff
                    min_diff = time_diff;
                    best_match_A = candidate_A;
                end
            end
        end

        % 如果没有不交叉的匹配，选择时间最近的匹配点
        if isempty(best_match_A) && ~isempty(candidates)
            [~, idx] = min(abs(tB(current_idx_B) - tA(candidates)));
            best_match_A = candidates(idx);
        end

        % 如果找到最佳匹配，加入匹配路径
        if ~isempty(best_match_A)
            global_path_sorted = [global_path_sorted; best_match_A, current_idx_B];
            global_path_sorted = sortrows(global_path_sorted, 1); % 保证排序
        end
    end

    % 调整匹配路径，防止交叉
    for i = 1:size(global_path_sorted, 1) - 1
        if global_path_sorted(i, 1) > global_path_sorted(i + 1, 1)
            % 如果当前匹配对的A轨迹时间大于下一匹配对的A轨迹时间，则交换这两个匹配对
            temp = global_path_sorted(i, :);
            global_path_sorted(i, :) = global_path_sorted(i + 1, :);
            global_path_sorted(i + 1, :) = temp;
        end
    end
    % 阶段4：匹配剩余区域（防止交叉匹配）
    matched_A = false(size(tA));
    matched_B = false(size(tB));
    if ~isempty(global_path_sorted)
        matched_A(global_path_sorted(:, 1)) = true;
        matched_B(global_path_sorted(:, 2)) = true;
    end

    % 获取未匹配区域
    unmatched_A = find(~matched_A);
    unmatched_B = find(~matched_B);
    % 处理未匹配点，将它们匹配到最近的匹配对对应的轨迹
    for i = 1:length(unmatched_A)
        current_idx_A = unmatched_A(i);

        % 找到已经匹配的A轨迹点中，最接近当前未匹配A轨迹点的
        [~, closest_match_idx] = min(abs(tA(current_idx_A) - tA(global_path_sorted(:, 1))));

        % 获取对应匹配对中的B轨迹点
        closest_B = global_path_sorted(closest_match_idx, 2);

        % 将当前未匹配的A轨迹点与该B轨迹点匹配
        global_path_sorted = [global_path_sorted; current_idx_A, closest_B];
    end

    for i = 1:length(unmatched_B)
        current_idx_B = unmatched_B(i);

        % 找到已经匹配的B轨迹点中，最接近当前未匹配B轨迹点的
        [~, closest_match_idx] = min(abs(tB(current_idx_B) - tB(global_path_sorted(:, 2))));

        % 获取对应匹配对中的A轨迹点
        closest_A = global_path_sorted(closest_match_idx, 1);

        % 将当前未匹配的B轨迹点与该A轨迹点匹配
        global_path_sorted = [global_path_sorted; closest_A, current_idx_B];
    end

    % 如果还需要根据B轨迹时间顺序调整，可以进一步处理
    for i = 1:size(global_path_sorted, 1) - 1
        if global_path_sorted(i, 2) > global_path_sorted(i + 1, 2)
            % 如果当前匹配对的B轨迹时间大于下一匹配对的B轨迹时间，则交换这两个匹配对
            temp = global_path_sorted(i, :);
            global_path_sorted(i, :) = global_path_sorted(i + 1, :);
            global_path_sorted(i + 1, :) = temp;
        end
    end


% 最终排序并提取tau和d
global_path_sorted = sortrows(global_path_sorted, [1, 2]);
tau = tB(global_path_sorted(:, 2)) - tA(global_path_sorted(:, 1));
d = pA(global_path_sorted(:, 1)) - pB(global_path_sorted(:, 2));

% 过滤无效的tau和d
valid = tau > 0 & d > 0;
tau = tau(valid);
d = d(valid);
end