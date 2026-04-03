FileNames={};
while true
[fileNames, filePath] = uigetfile('*.txt', '选择txt文件', 'MultiSelect', 'on'); % 打开文件选择对话框并启用多选功能

if isequal(fileNames, 0) % 用户取消了选择
    disp('未选择任何文件');
    break
else
    if ~iscell(fileNames) % 用户只选择了一个文件
        fileNames = {fileNames}; % 将文件名转换为单元格数组
    end
    for i = 1:length(fileNames)
        fileName = fileNames{i};
        fullPath = fullfile(filePath, fileName); % 获取完整的文件路径
        disp("'"+fullPath+"'");
        FileNames{end+1}=fullPath;

        % 在这里可以继续编写处理Excel文件的代码
    end
end
end
%%
% fileNames = {'D:\毕业设计数据库\1-1\1_1_revised(1)_0.csv'};%excel列表名
sheet = 1; % 工作表索引
% columnX = 5; % X列范围
% columnY = 6; % Y列范围
% columnv=7;
% columnt=10;
% columnL=12;
% columnD=13;
% columnn=2;
data_NGSIM = [];
id_offset = 0; % ID偏移量初始化

% 定义列名（14列）
variableNames = {'vehicleid', 'frameid', 'totalframe', 'globaltime', ...
                'x', 'y', 'globalx', 'globaly', 'vlength', 'vwidth', ...
                'vtype', 'vspeed', 'vacc', 'laneid'};

for i = 1:numel(FileNames)
    filename = FileNames{i};
    
    % --- 逐行读取并处理行首空格 ---
    fid = fopen(filename, 'r');
    dataCells = textscan(fid, '%s', 'Delimiter', '\n');
    fclose(fid);
    lines = dataCells{1};
    
    % 逐行解析数据
    numLines = numel(lines);
    dataArray = zeros(numLines, 14);
    
    for k = 1:numLines
        line = strtrim(lines{k});
        values = sscanf(line, '%f');
        
        if numel(values) >= 14
            dataArray(k, :) = values(1:14)';
        else
            warning('第 %d 行数据不足14列，已跳过', k);
        end
    end
    
    % 转换为table
    data = array2table(dataArray, 'VariableNames', variableNames);
    
    % 为当前文件的vehicleid添加唯一标识（方法1：加偏移量）
    data.vehicleid = data.vehicleid + id_offset;
    
    % 或者方法2：添加文件前缀（需先将vehicleid转为字符串）
    % data.vehicleid = strcat(num2str(i), '_', num2str(data.vehicleid));
    
    % 更新偏移量为当前最大ID（确保下个文件不会重复）
    id_offset = max(data.vehicleid);
    
    % 筛选条件（例如 laneid == 1）
    condition = data.laneid == 1;
    selectedData = data(condition, :);
    
    % 合并数据
    data_NGSIM = [data_NGSIM; selectedData];
end
data_NGSIM.globaltime = data_NGSIM.globaltime-min(data_NGSIM.globaltime);
%%
% 定义时间阈值（1.11885×10^12）
time_threshold = 730; 
% 定义需要提取的列
selected_columns = {'globaltime', 'y', 'vspeed', 'vacc'}; % 请确保列名完全匹配
% 筛选条件：globaltime < time_threshold
time_mask = data_NGSIM.globaltime < time_threshold;
filtered_data = data_NGSIM(time_mask, :);

% 按车辆ID分组存储到trajectory_cell中
vehicle_ids = unique(filtered_data.vehicleid);
trajectory_cell = cell(length(vehicle_ids), 1);

for i = 1:length(vehicle_ids)
    % 提取当前车辆的所有轨迹点（已自动满足时间条件）
    vehicle_mask = (filtered_data.vehicleid == vehicle_ids(i));
    trajectory_cell{i} = filtered_data(vehicle_mask, selected_columns);
    
    % 按时间排序（可选）
    [~, idx2] = sort(trajectory_cell{i}.globaltime);
    trajectory_cell{i} = trajectory_cell{i}(idx2, :);
end

%%
% 获取所有唯一的车辆ID
car_ids2 = unique(data_new3.track_id);
num_vehicles2 = length(car_ids2);

% 预分配存储
valid_flags2 = false(num_vehicles2, 1); % 标记满足初始条件的车辆
vehicle_trajectories2 = cell(num_vehicles2, 1); % 存储每辆车的完整轨迹

% 第一阶段：筛选满足x范围条件的车辆
for i = 1:num_vehicles2
    current_id2 = car_ids2(i);
    points2 = data_new3(data_new3.track_id == current_id2, :);
    
    % 按时间排序
    [~, idx2] = sort(points2.time);
    points2 = points2(idx2, :);
    
    % 检查初始条件
    if height(points2)>200
        valid_flags2(i) = true;
        vehicle_trajectories2{i} = points2;
    end
end

valid_indices2 = find(valid_flags2);
num_valid2 = length(valid_indices2);

% 碰撞检测参数
min_collision_gap = 5; % 视为碰撞的最大距离阈值(单位同x坐标)
time_tolerance = 2;    % 时间同步容差(单位同时间数据)

% 初始化碰撞关系矩阵
collision_relations2 = zeros(num_valid2, num_valid2); % 记录车辆间的碰撞关系
collision_flags2 = false(num_valid2, 1); % 标记有碰撞的车辆

% 建立完整的碰撞关系图
for i = 1:num_valid2
    traj_i2 = vehicle_trajectories2{valid_indices2(i)};
    
    for j = i+1:num_valid2
        traj_j2 = vehicle_trajectories2{valid_indices2(j)};
        
        % 找出两车共同的时间段
        common_time_start2 = max(min(traj_i2.time), min(traj_j2.time));
        common_time_end2 = min(max(traj_i2.time), max(traj_j2.time));
        
        if common_time_start2 >= common_time_end2
            continue; % 无共同时间段
        end
        
        % 在共同时间段内插值检测
        evaluation_times2 = linspace(common_time_start2, common_time_end2, 100);
        
        % 插值获取两车位置
        x_i2 = interp1(traj_i2.time, traj_i2.x, evaluation_times2, 'linear', 'extrap');
        x_j2 = interp1(traj_j2.time, traj_j2.x, evaluation_times2, 'linear', 'extrap');
        
        % 计算距离
        distances2 = abs(x_i2 - x_j2);
        
        % 检测是否有碰撞点
        if any(distances2 <= min_collision_gap)
            collision_relations2(i,j) = 1;
            collision_relations2(j,i) = 1;
            collision_flags2(i) = true;
            collision_flags2(j) = true;
        end
    end
end

% 计算每辆车的碰撞总数
collision_counts2 = sum(collision_relations2, 2);

% 初始恢复：处理互相唯一碰撞的情况
recoverable2 = false(num_valid2, 1);
processed_pairs2 = zeros(num_valid2, num_valid2);

% 按碰撞次数升序处理车辆，确保碰撞少的优先被考虑
[sorted_counts, sort_order2] = sort(collision_counts2);
sorted_indices2 = 1:num_valid2;
sorted_indices2 = sorted_indices2(sort_order2);

for idx2 = 1:num_valid2
    i = sorted_indices2(idx2);
    if collision_flags2(i)
        collided_with2 = find(collision_relations2(i,:));
        
        for j = collided_with2
            if processed_pairs2(i,j) || processed_pairs2(j,i)
                continue;
            end
            
            other_collisions2 = sum(collision_relations2(j,:)) - collision_relations2(j,i);
            
            if other_collisions2 == 0
                % 检查是否是互相唯一碰撞的情况
                if sum(collision_relations2(i,:)) - collision_relations2(i,j) == 0
                    % 两辆车互相只与对方碰撞，优先恢复碰撞次数少的
                    if collision_counts2(i) < collision_counts2(j)
                        recoverable2(i) = true;
                    elseif collision_counts2(i) > collision_counts2(j)
                        recoverable2(j) = true;
                    else
                        % 碰撞次数相同，按ID排序
                        if car_ids2(valid_indices2(i)) < car_ids2(valid_indices2(j))
                            recoverable2(i) = true;
                        else
                            recoverable2(j) = true;
                        end
                    end
                    processed_pairs2(i,j) = 1;
                    processed_pairs2(j,i) = 1;
                else
                    % 正常情况，可以恢复
                    recoverable2(j) = true;
                end
            end
        end
    end
end

% 迭代恢复：处理"所有碰撞车辆都在碰撞集合中"的情况
changed2 = true;
iteration2 = 0;
max_iterations = 10;

while changed2 && iteration2 < max_iterations
    changed2 = false;
    iteration2 = iteration2 + 1;
    
    % 按碰撞次数升序处理当前碰撞车辆
    current_collided2 = find(collision_flags2 & ~recoverable2);
    [~, sort_order2] = sort(collision_counts2(current_collided2));
    current_collided2 = current_collided2(sort_order2);
    
    for k = 1:length(current_collided2)
        i = current_collided2(k);
        collided_with2 = find(collision_relations2(i,:));
        
        % 检查所有与之碰撞的车辆是否都在碰撞集合中(未被恢复)
        all_collided_in_set2 = true;
        for j = collided_with2
            if ~collision_flags2(j) || recoverable2(j)
                all_collided_in_set2 = false;
                break;
            end
        end
        
        % 如果所有碰撞车辆都在碰撞集合中，则可以恢复当前车辆
        if all_collided_in_set2 && ~isempty(collided_with2)
            recoverable2(i) = true;
            changed2 = true;
        end
    end
end

% 构建最终结果
final_data2 = table();
final_flags2 = collision_flags2; % 初始化最终标记

% 应用所有恢复标记
for i = 1:num_valid2
    if recoverable2(i)
        final_flags2(i) = false; % 恢复为安全车辆
    end
end

% 收集最终安全车辆的数据
for i = 1:num_valid2
    if ~final_flags2(i)
        final_data2 = [final_data2; vehicle_trajectories2{valid_indices2(i)}];
    end
end

% 绘图展示
figure;
hold on;
grid on;
xlabel('Global Time');
ylabel('X Position');
title('Filtered Vehicle Trajectories with Iterative Recovery');

% 颜色定义
safe_color = [0 0.5 0]; % 深绿色表示安全
collided_color = [1 0.5 0.5]; % 淡红色表示碰撞
recovered_color = [0.8 0.8 0]; % 黄色表示被恢复的车辆
iter_recovered_color = [0.5 0.8 0.8]; % 青色表示迭代恢复的车辆

% 绘制安全车辆轨迹(包括被恢复的)
for i = 1:num_valid2
    if ~final_flags2(i)
        traj2 = vehicle_trajectories2{valid_indices2(i)};
        
        % 检查恢复类型
        if recoverable2(i)
            % 检查是初始恢复还是迭代恢复
            collided_with2 = find(collision_relations2(i,:));
            all_in_collision2 = true;
            for j = collided_with2
                if ~collision_flags2(j) || recoverable2(j)
                    all_in_collision2 = false;
                    break;
                end
            end
            
            if all_in_collision2 && ~isempty(collided_with2)
                % 迭代恢复的车辆
                plot(traj2.time, traj2.x, 'LineWidth', 1.5, 'Color', iter_recovered_color, ...
                    'DisplayName', sprintf('Iter-Recovered Veh %d', car_ids2(valid_indices2(i))));
            else
                % 初始恢复的车辆
                plot(traj2.time, traj2.x, 'LineWidth', 1.5, 'Color', recovered_color, ...
                    'DisplayName', sprintf('Recovered Veh %d', car_ids2(valid_indices2(i))));
            end
        else
            % 始终安全的车辆
            plot(traj2.time, traj2.x, 'LineWidth', 1.5, 'Color', safe_color, ...
                'DisplayName', sprintf('Safe Veh %d', car_ids2(valid_indices2(i))));
        end
    end
end

% 绘制仍然有碰撞的车辆
for i = 1:num_valid2
    if final_flags2(i)
        traj2 = vehicle_trajectories2{valid_indices2(i)};
        plot(traj2.time, traj2.x, ':', 'Color', collided_color, ...
            'DisplayName', sprintf('Collided Veh %d', car_ids2(valid_indices2(i))));
    end
end

hold off;
legend('Location', 'bestoutside');

% 输出结果
original_collisions2 = sum(collision_flags2);
final_collisions2 = sum(final_flags2);
initial_recovered2 = sum(recoverable2 & ~final_flags2);
iter_recovered2 = sum(recoverable2) - initial_recovered2;

fprintf('总检测车辆: %d\n', num_vehicles2);
fprintf('满足初始条件: %d\n', num_valid2);
fprintf('初始碰撞车辆: %d\n', original_collisions2);
fprintf('初始恢复的安全车辆: %d\n', initial_recovered2);
fprintf('迭代恢复的安全车辆: %d\n', iter_recovered2);
fprintf('最终碰撞车辆: %d\n', final_collisions2);
fprintf('最终安全车辆: %d\n', num_valid2 - final_collisions2);

%%
% 获取所有安全车辆的ID（即final_flags2为false的车辆）
safe_vehicle_indices2 = valid_indices2(~final_flags2);
safe_vehicle_ids2 = car_ids2(safe_vehicle_indices2);

% 从final_data2中筛选出这些安全车辆的数据
safe_vehicles_dataset2 = final_data2(ismember(final_data2.track_id, safe_vehicle_ids2), :);

% 可选：按车辆ID和时间排序
safe_vehicles_dataset2 = sortrows(safe_vehicles_dataset2, {'track_id', 'time'});

% 显示结果信息
fprintf('已创建安全车辆数据集，包含 %d 辆车的 %d 条轨迹数据\n', ...
    length(safe_vehicle_ids2), height(safe_vehicles_dataset2));
%%
% % 获取所有唯一的车辆ID
% car = unique(data_new.track_id);
% 
% % 创建新图形窗口
% figure;
% hold on;  % 保持图形，允许多条曲线叠加
% grid on;  % 显示网格
% xlabel('Global Time');
% ylabel('X Position');
% title('Vehicle Trajectories: X Position vs. Time');
% 
% % 为不同车辆分配不同颜色
% colors = lines(length(car));  % 使用lines配色方案，确保每条线颜色不同
% 
% for i = 1:382
%     % 提取当前车辆的数据
%     vehicle_id = car(i);
%     points2 = data_new(data_new.track_id == vehicle_id, :);
% 
%     % 按时间排序（确保连线顺序正确）
%     [~, idx2] = sort(points2.time);
%     points2 = points2(idx2, :);
% 
%     % 绘制轨迹（使用连续线条）
%     plot(points2.time, points2.x, ...
%          'LineWidth', 1,  ...
%          'DisplayName', sprintf('Vehicle %d', vehicle_id));
% end
% 
% 
% hold off;
% 获取所有唯一的车辆ID
car = unique(data_new.track_id);

% 创建新图形窗口
figure;
hold on;  % 保持图形，允许多条曲线叠加
grid on;  % 显示网格
xlabel('Global Time');
ylabel('X Position');
title('Vehicle Trajectories with Threshold Markers');

% 定义颜色和样式
highlight_color = [1 0 0]; % 红色
normal_color = [0.8 0.8 0.8]; % 浅灰色
marker_color = 'm'; % 品红色标记点
tolerance = 1; % 允许的误差范围
threshold = 351750; % 阈值距离
threshold2 = 352120; % 阈值距离
threshold3 = 351925; % 阈值距离
for i = 1:355
    % 提取当前车辆的数据
    vehicle_id = car(i);
    points2 = data_new(data_new.track_id == vehicle_id, :);
    
    % 按时间排序（确保连线顺序正确）
    [~, idx2] = sort(points2.time);
    points2 = points2(idx2, :);
    
    % 确定当前车辆的颜色和样式
    if mod(i, 15) == 0  % 每隔20辆车
        line_color = highlight_color;
        line_style = '-';
        line_width = 1.5;
        display_name = sprintf('Vehicle %d', vehicle_id);
    else
        line_color = normal_color;
        line_style = '-';
        line_width = 0.5;
        display_name = ''; % 不显示在图例中
    end
    
    % 绘制轨迹线
    plot(points2.time, points2.x, ...
         'Color', line_color, ...
         'LineStyle', line_style, ...
         'LineWidth', line_width, ...
         'DisplayName', display_name);
    
    % 查找并标记阈值点
    threshold_index = find(points2.x >= threshold-tolerance & ...
                          points2.x <= threshold+tolerance, 1, 'first');
    threshold_index2 = find(points2.x >= threshold2-tolerance & ...
                          points2.x <= threshold2+tolerance, 1, 'first');
    
    if ~isempty(threshold_index)
        % 绘制标记点（品红色星号）
        plot(points2.time(threshold_index), points2.x(threshold_index), ...
             [marker_color '*'], ...
             'MarkerSize', 5, ...
             'HandleVisibility', 'off'); % 不在图例中显示标记点
    end
     if ~isempty(threshold_index2)
        % 绘制标记点（品红色星号）
        plot(points2.time(threshold_index2), points2.x(threshold_index2), ...
             [marker_color '*'], ...
             'MarkerSize', 5, ...
             'HandleVisibility', 'off'); % 不在图例中显示标记点
    end

end

% 添加图例只显示车辆轨迹
legend('Location', 'bestoutside');
hold off;
%%
figure;
hold on;
for i = 1:length(trajectory_cell)  % 最多显示20条
    data = trajectory_cell{i};
    plot(data.globaltime, data.y);
end
xlabel('Time');
ylabel('Distance');
title('筛选后的车辆轨迹（距离范围：min<10, max>2000）');
legend('show', 'Location', 'best');
grid on;