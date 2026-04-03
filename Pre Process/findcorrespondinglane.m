FileNames={};
while true
[fileNames, filePath] = uigetfile('*.csv', '选择Excel文件', 'MultiSelect', 'on'); % 打开文件选择对话框并启用多选功能

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
% 获取所有唯一的车辆ID
car_ids = unique(data_new2.track_id);
num_vehicles = length(car_ids);

% 预分配存储
valid_flags = false(num_vehicles, 1); % 标记满足初始条件的车辆
vehicle_trajectories = cell(num_vehicles, 1); % 存储每辆车的完整轨迹

% 第一阶段：筛选满足x范围条件的车辆
for i = 1:num_vehicles
    current_id = car_ids(i);
    points = data_new2(data_new2.track_id == current_id, :);
    
    % 按时间排序
    [~, idx] = sort(points.time);
    points = points(idx, :);
    
    % 检查初始条件
    if height(points)>1200
        valid_flags(i) = true;
        vehicle_trajectories{i} = points;
    end
end

valid_indices = find(valid_flags);
num_valid = length(valid_indices);

% 碰撞检测参数
min_collision_gap = 5; % 视为碰撞的最大距离阈值(单位同x坐标)
time_tolerance = 2;    % 时间同步容差(单位同时间数据)

% 初始化碰撞关系矩阵
collision_relations = zeros(num_valid, num_valid); % 记录车辆间的碰撞关系
collision_flags = false(num_valid, 1); % 标记有碰撞的车辆

% 建立完整的碰撞关系图
for i = 1:num_valid
    traj_i = vehicle_trajectories{valid_indices(i)};
    
    for j = i+1:num_valid
        traj_j = vehicle_trajectories{valid_indices(j)};
        
        % 找出两车共同的时间段
        common_time_start = max(min(traj_i.time), min(traj_j.time));
        common_time_end = min(max(traj_i.time), max(traj_j.time));
        
        if common_time_start >= common_time_end
            continue; % 无共同时间段
        end
        
        % 在共同时间段内插值检测
        evaluation_times = linspace(common_time_start, common_time_end, 100);
        
        % 插值获取两车位置
        x_i = interp1(traj_i.time, traj_i.x, evaluation_times, 'linear', 'extrap');
        x_j = interp1(traj_j.time, traj_j.x, evaluation_times, 'linear', 'extrap');
        
        % 计算距离
        distances = abs(x_i - x_j);
        
        % 检测是否有碰撞点
        if any(distances <= min_collision_gap)
            collision_relations(i,j) = 1;
            collision_relations(j,i) = 1;
            collision_flags(i) = true;
            collision_flags(j) = true;
        end
    end
end

% 计算每辆车的碰撞总数
collision_counts = sum(collision_relations, 2);

% 初始恢复：处理互相唯一碰撞的情况
recoverable = false(num_valid, 1);
processed_pairs = zeros(num_valid, num_valid);

% 按碰撞次数升序处理车辆，确保碰撞少的优先被考虑
[sorted_counts, sort_order] = sort(collision_counts);
sorted_indices = 1:num_valid;
sorted_indices = sorted_indices(sort_order);

for idx = 1:num_valid
    i = sorted_indices(idx);
    if collision_flags(i)
        collided_with = find(collision_relations(i,:));
        
        for j = collided_with
            if processed_pairs(i,j) || processed_pairs(j,i)
                continue;
            end
            
            other_collisions = sum(collision_relations(j,:)) - collision_relations(j,i);
            
            if other_collisions == 0
                % 检查是否是互相唯一碰撞的情况
                if sum(collision_relations(i,:)) - collision_relations(i,j) == 0
                    % 两辆车互相只与对方碰撞，优先恢复碰撞次数少的
                    if collision_counts(i) < collision_counts(j)
                        recoverable(i) = true;
                    elseif collision_counts(i) > collision_counts(j)
                        recoverable(j) = true;
                    else
                        % 碰撞次数相同，按ID排序
                        if car_ids(valid_indices(i)) < car_ids(valid_indices(j))
                            recoverable(i) = true;
                        else
                            recoverable(j) = true;
                        end
                    end
                    processed_pairs(i,j) = 1;
                    processed_pairs(j,i) = 1;
                else
                    % 正常情况，可以恢复
                    recoverable(j) = true;
                end
            end
        end
    end
end

% 迭代恢复：处理"所有碰撞车辆都在碰撞集合中"的情况
changed = true;
iteration = 0;
max_iterations = 10;

while changed && iteration < max_iterations
    changed = false;
    iteration = iteration + 1;
    
    % 按碰撞次数升序处理当前碰撞车辆
    current_collided = find(collision_flags & ~recoverable);
    [~, sort_order] = sort(collision_counts(current_collided));
    current_collided = current_collided(sort_order);
    
    for k = 1:length(current_collided)
        i = current_collided(k);
        collided_with = find(collision_relations(i,:));
        
        % 检查所有与之碰撞的车辆是否都在碰撞集合中(未被恢复)
        all_collided_in_set = true;
        for j = collided_with
            if ~collision_flags(j) || recoverable(j)
                all_collided_in_set = false;
                break;
            end
        end
        
        % 如果所有碰撞车辆都在碰撞集合中，则可以恢复当前车辆
        if all_collided_in_set && ~isempty(collided_with)
            recoverable(i) = true;
            changed = true;
        end
    end
end

% 构建最终结果
final_data = table();
final_flags = collision_flags; % 初始化最终标记

% 应用所有恢复标记
for i = 1:num_valid
    if recoverable(i)
        final_flags(i) = false; % 恢复为安全车辆
    end
end

% 收集最终安全车辆的数据
for i = 1:num_valid
    if ~final_flags(i)
        final_data = [final_data; vehicle_trajectories{valid_indices(i)}];
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
for i = 1:num_valid
    if ~final_flags(i)
        traj = vehicle_trajectories{valid_indices(i)};
        
        % 检查恢复类型
        if recoverable(i)
            % 检查是初始恢复还是迭代恢复
            collided_with = find(collision_relations(i,:));
            all_in_collision = true;
            for j = collided_with
                if ~collision_flags(j) || recoverable(j)
                    all_in_collision = false;
                    break;
                end
            end
            
            if all_in_collision && ~isempty(collided_with)
                % 迭代恢复的车辆
                plot(traj.time, traj.x, 'LineWidth', 1.5, 'Color', iter_recovered_color, ...
                    'DisplayName', sprintf('Iter-Recovered Veh %d', car_ids(valid_indices(i))));
            else
                % 初始恢复的车辆
                plot(traj.time, traj.x, 'LineWidth', 1.5, 'Color', recovered_color, ...
                    'DisplayName', sprintf('Recovered Veh %d', car_ids(valid_indices(i))));
            end
        else
            % 始终安全的车辆
            plot(traj.time, traj.x, 'LineWidth', 1.5, 'Color', safe_color, ...
                'DisplayName', sprintf('Safe Veh %d', car_ids(valid_indices(i))));
        end
    end
end

% 绘制仍然有碰撞的车辆
for i = 1:num_valid
    if final_flags(i)
        traj = vehicle_trajectories{valid_indices(i)};
        plot(traj.time, traj.x, ':', 'Color', collided_color, ...
            'DisplayName', sprintf('Collided Veh %d', car_ids(valid_indices(i))));
    end
end

hold off;
legend('Location', 'bestoutside');

% 输出结果
original_collisions = sum(collision_flags);
final_collisions = sum(final_flags);
initial_recovered = sum(recoverable & ~final_flags);
iter_recovered = sum(recoverable) - initial_recovered;

fprintf('总检测车辆: %d\n', num_vehicles);
fprintf('满足初始条件: %d\n', num_valid);
fprintf('初始碰撞车辆: %d\n', original_collisions);
fprintf('初始恢复的安全车辆: %d\n', initial_recovered);
fprintf('迭代恢复的安全车辆: %d\n', iter_recovered);
fprintf('最终碰撞车辆: %d\n', final_collisions);
fprintf('最终安全车辆: %d\n', num_valid - final_collisions);
%%
% 获取所有安全车辆的ID（即final_flags2为false的车辆）
safe_vehicle_indices = valid_indices(~final_flags);
safe_vehicle_ids = car_ids2(safe_vehicle_indices);

% 从final_data2中筛选出这些安全车辆的数据
safe_vehicles_dataset = final_data2(ismember(final_data2.track_id, safe_vehicle_ids), :);

% 可选：按车辆ID和时间排序
safe_vehicles_dataset = sortrows(safe_vehicles_dataset, {'track_id', 'time'});

% 显示结果信息
fprintf('已创建安全车辆数据集，包含 %d 辆车的 %d 条轨迹数据\n', ...
    length(safe_vehicle_ids), height(safe_vehicles_dataset));
%%
sheet = 1; % 工作表索引
data_whole2 = [];

for i = 1:numel(FileNames)
    filename = FileNames{i};
    data = readtable(filename, 'PreserveVariableNames', true);
    
    % 筛选条件
    condition2 = data.direction == 1;
    condition4 = data.time <= 4000;
    condition6 = data.time >= 3000;
    condition7 = data.lane_id == 3;
    
    combinedCondition = condition7 & condition2 & condition4 & condition6;
    selectedData = data(combinedCondition, :);
    
    % 如果是第一个文件，添加flag列并赋值为0
    if i == 1
        % 获取当前列数
        numCols = width(selectedData);
        % 添加新列flag
        selectedData.flag = zeros(height(selectedData), 1);
        % 如果需要将新列放在最后（MATLAB默认会加在最后）
        % selectedData = [selectedData, array2table(zeros(height(selectedData),1), 'VariableNames', {'flag'})];
    end
    
    data_whole2 = [data_whole2; selectedData];
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
data_whole2=[];
% dataX = []; % 存储所有X列数据
% dataY = []; % 存储所有Y列数据
% datav=[];
% datat=[];
% variableNames ={"A" , "B", "C","D","E","F","G","H","I","J","K","L","M"};
for i = 1:numel(FileNames)
    filename = FileNames{i};
    data=readtable(filename, 'PreserveVariableNames', true);
    % 筛选某列数据
    % 例如，选择"Size"为'Large'且"Age"大于30的行
    % condition1 = strcmp(data.Var2, 'Car');
    condition2 = data.direction == 1;
    condition4 = data.time <= 4000;
    condition6 = data.time>= 3000;
    % condition1 = data.x<=352000;
    % condition5 = data.x>=351500;
    % condition5 = mod(data.Var1,1) == 0; 
    condition7 = data.lane_id == 2;
    % condition8 = data.flag == 1;
    % condition1 = data.Va1 >=6000;
    % condition5 = data.Var1 <=6500;

    % 使用逻辑与操作符组合两个条件
    combinedCondition =  condition7 & condition2&condition4&condition6;%&condition5&condition1;

    % 使用组合后的逻辑索引筛选符合条件的行
    selectedData = data(combinedCondition, :);
  
    % filterCondition = (columnt1<=50000); % 将your_condition替换为你的筛选条件
    % 选择满足条件的行和对应的其他列数据
    % filteredData = data(logical(filterCondition), :);
    data_part2=selectedData(:,:);
    
    data_whole2=[data_whole2;data_part2];


    % dataX_temp = abs(filteredData(:, columnX)); % 导入当前表的X列数据
    % dataY_temp = (filteredData(:, columnY)); % 导入当前表的Y列数据
    % datat_temp=abs(filteredData(:, columnt));
    % datav_temp=abs(filteredData(:, columnv));
    % 
    % dataX = [dataX; dataX_temp]; % 将当前表的X列数据添加到总体数据中
    % dataY = [dataY; dataY_temp]; % 将当前表的Y列数据添加到总体数据中
    % datat=[datat;datat_temp];
    % datav=[datav;datav_temp];
end
%%
% 假设data_new和data_whole2是table类型
common_ids = intersect(safe_vehicles_dataset{:,1},safe_vehicles_dataset3{:,1});

% 显示结果
disp('重复的ID有：');
disp(common_ids);
%%
car = unique(data_new3.track_id);

% 创建新图形窗口
figure;
hold on;  % 保持图形，允许多条曲线叠加
grid on;  % 显示网格
xlabel('Global Time');
ylabel('X Position');
title('Vehicle Trajectories: X Position vs. Time');

% 为不同车辆分配不同颜色
colors = lines(length(car));  % 使用lines配色方案，确保每条线颜色不同

for i = 1:height(car)
    % 提取当前车辆的数据
    vehicle_id =  2927;
    points2 = data_new3(data_new3.track_id == vehicle_id, :);
   
        % 按时间排序（确保连线顺序正确）
        [~, idx2] = sort(points2.time);
        points2 = points2(idx2, :);

        % 绘制轨迹（使用连续线条）
        plot(points2.time, points2.x, ...
            'LineWidth', 1,  ...
            'DisplayName', sprintf('Vehicle %d', vehicle_id));
    
end

% 创建新图形窗口
figure;
hold on;  % 保持图形，允许多条曲线叠加
grid on;  % 显示网格
xlabel('Global Time');
ylabel('X Position');
title('Vehicle Trajectories: X Position vs. Time');

car = unique(data_whole2.track_id);
for i = 1:height(car)
    % 提取当前车辆的数据
    vehicle_id = 2927;
    points3 = data_new2(data_new2.track_id == vehicle_id, :);
    
        % 按时间排序（确保连线顺序正确）
        [~, idx2] = sort(points3.time);
        points3 = points3(idx2, :);

        % 绘制轨迹（使用连续线条）
        plot(points3.time, points3.x, ...
            'LineWidth', 1,  ...
            'DisplayName', sprintf('Vehicle %d', vehicle_id));

end

hold off;

%%
% 获取所有唯一的车辆ID
car_ids3 = unique(data_new4.track_id);
num_vehicles3 = length(car_ids3);

% 预分配存储
valid_flags3 = false(num_vehicles3, 1); % 标记满足初始条件的车辆
vehicle_trajectories3 = cell(num_vehicles3, 1); % 存储每辆车的完整轨迹

% 第一阶段：筛选满足x范围条件的车辆
for i = 1:num_vehicles3
    current_id3 = car_ids3(i);
    points3 = data_new4(data_new4.track_id == current_id3, :);
    
    % 按时间排序
    [~, idx3] = sort(points3.time);
    points3 = points3(idx3, :);
    
    % 检查初始条件
    if height(points3)>500
        valid_flags3(i) = true;
        vehicle_trajectories3{i} = points3;
    end
end

valid_indices3 = find(valid_flags3);
num_valid3 = length(valid_indices3);

% 碰撞检测参数
min_collision_gap = 5; % 视为碰撞的最大距离阈值(单位同x坐标)
time_tolerance = 2;    % 时间同步容差(单位同时间数据)

% 初始化碰撞关系矩阵
collision_relations3 = zeros(num_valid3, num_valid3); % 记录车辆间的碰撞关系
collision_flags3 = false(num_valid3, 1); % 标记有碰撞的车辆

% 建立完整的碰撞关系图
for i = 1:num_valid3
    traj_i3 = vehicle_trajectories3{valid_indices3(i)};
    
    for j = i+1:num_valid3
        traj_j3 = vehicle_trajectories3{valid_indices3(j)};
        
        % 找出两车共同的时间段
        common_time_start3 = max(min(traj_i3.time), min(traj_j3.time));
        common_time_end3 = min(max(traj_i3.time), max(traj_j3.time));
        
        if common_time_start3 >= common_time_end3
            continue; % 无共同时间段
        end
        
        % 在共同时间段内插值检测
        evaluation_times3 = linspace(common_time_start3, common_time_end3, 100);
        
        % 插值获取两车位置
        x_i3 = interp1(traj_i3.time, traj_i3.x, evaluation_times3, 'linear', 'extrap');
        x_j3 = interp1(traj_j3.time, traj_j3.x, evaluation_times3, 'linear', 'extrap');
        
        % 计算距离
        distances3 = abs(x_i3 - x_j3);
        
        % 检测是否有碰撞点
        if any(distances3 <= min_collision_gap)
            collision_relations3(i,j) = 1;
            collision_relations3(j,i) = 1;
            collision_flags3(i) = true;
            collision_flags3(j) = true;
        end
    end
end

% 计算每辆车的碰撞总数
collision_counts3 = sum(collision_relations3, 2);

% 初始恢复：处理互相唯一碰撞的情况
recoverable3 = false(num_valid3, 1);
processed_pairs3 = zeros(num_valid3, num_valid3);

% 按碰撞次数升序处理车辆，确保碰撞少的优先被考虑
[sorted_counts3, sort_order3] = sort(collision_counts3);
sorted_indices3 = 1:num_valid3;
sorted_indices3 = sorted_indices3(sort_order3);

for idx3 = 1:num_valid3
    i = sorted_indices3(idx3);
    if collision_flags3(i)
        collided_with3 = find(collision_relations3(i,:));
        
        for j = collided_with3
            if processed_pairs3(i,j) || processed_pairs3(j,i)
                continue;
            end
            
            other_collisions3 = sum(collision_relations3(j,:)) - collision_relations3(j,i);
            
            if other_collisions3 == 0
                % 检查是否是互相唯一碰撞的情况
                if sum(collision_relations3(i,:)) - collision_relations3(i,j) == 0
                    % 两辆车互相只与对方碰撞，优先恢复碰撞次数少的
                    if collision_counts3(i) < collision_counts3(j)
                        recoverable3(i) = true;
                    elseif collision_counts3(i) > collision_counts3(j)
                        recoverable3(j) = true;
                    else
                        % 碰撞次数相同，按ID排序
                        if car_ids3(valid_indices3(i)) < car_ids3(valid_indices3(j))
                            recoverable3(i) = true;
                        else
                            recoverable3(j) = true;
                        end
                    end
                    processed_pairs3(i,j) = 1;
                    processed_pairs3(j,i) = 1;
                else
                    % 正常情况，可以恢复
                    recoverable3(j) = true;
                end
            end
        end
    end
end

% 迭代恢复：处理"所有碰撞车辆都在碰撞集合中"的情况
changed3 = true;
iteration3 = 0;
max_iterations = 10;

while changed3 && iteration3 < max_iterations
    changed3 = false;
    iteration3 = iteration3 + 1;
    
    % 按碰撞次数升序处理当前碰撞车辆
    current_collided3 = find(collision_flags3 & ~recoverable3);
    [~, sort_order3] = sort(collision_counts3(current_collided3));
    current_collided3 = current_collided3(sort_order3);
    
    for k = 1:length(current_collided3)
        i = current_collided3(k);
        collided_with3 = find(collision_relations3(i,:));
        
        % 检查所有与之碰撞的车辆是否都在碰撞集合中(未被恢复)
        all_collided_in_set3 = true;
        for j = collided_with3
            if ~collision_flags3(j) || recoverable3(j)
                all_collided_in_set3 = false;
                break;
            end
        end
        
        % 如果所有碰撞车辆都在碰撞集合中，则可以恢复当前车辆
        if all_collided_in_set3 && ~isempty(collided_with3)
            recoverable3(i) = true;
            changed3 = true;
        end
    end
end

% 构建最终结果
final_data3 = table();
final_flags3 = collision_flags3; % 初始化最终标记

% 应用所有恢复标记
for i = 1:num_valid3
    if recoverable3(i)
        final_flags3(i) = false; % 恢复为安全车辆
    end
end

% 收集最终安全车辆的数据
for i = 1:num_valid3
    if ~final_flags3(i)
        final_data3 = [final_data3; vehicle_trajectories3{valid_indices3(i)}];
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
for i = 1:num_valid3
    if ~final_flags3(i)
        traj3 = vehicle_trajectories3{valid_indices3(i)};
        
        % 检查恢复类型
        if recoverable3(i)
            % 检查是初始恢复还是迭代恢复
            collided_with3 = find(collision_relations3(i,:));
            all_in_collision3 = true;
            for j = collided_with3
                if ~collision_flags3(j) || recoverable3(j)
                    all_in_collision3 = false;
                    break;
                end
            end
            
            if all_in_collision3 && ~isempty(collided_with3)
                % 迭代恢复的车辆
                plot(traj3.time, traj3.x, 'LineWidth', 1.5, 'Color', iter_recovered_color, ...
                    'DisplayName', sprintf('Iter-Recovered Veh %d', car_ids3(valid_indices3(i))));
            else
                % 初始恢复的车辆
                plot(traj3.time, traj3.x, 'LineWidth', 1.5, 'Color', recovered_color, ...
                    'DisplayName', sprintf('Recovered Veh %d', car_ids3(valid_indices3(i))));
            end
        else
            % 始终安全的车辆
            plot(traj3.time, traj3.x, 'LineWidth', 1.5, 'Color', safe_color, ...
                'DisplayName', sprintf('Safe Veh %d', car_ids3(valid_indices3(i))));
        end
    end
end

% 绘制仍然有碰撞的车辆
for i = 1:num_valid3
    if final_flags3(i)
        traj3 = vehicle_trajectories3{valid_indices3(i)};
        plot(traj3.time, traj3.x, ':', 'Color', collided_color, ...
            'DisplayName', sprintf('Collided Veh %d', car_ids3(valid_indices3(i))));
    end
end

hold off;
legend('Location', 'bestoutside');

% 输出结果
original_collisions2 = sum(collision_flags3);
final_collisions3 = sum(final_flags3);
initial_recovered3 = sum(recoverable3 & ~final_flags3);
iter_recovered3 = sum(recoverable3) - initial_recovered3;

fprintf('总检测车辆: %d\n', num_vehicles3);
fprintf('满足初始条件: %d\n', num_valid3);
fprintf('初始碰撞车辆: %d\n', original_collisions2);
fprintf('初始恢复的安全车辆: %d\n', initial_recovered3);
fprintf('迭代恢复的安全车辆: %d\n', iter_recovered3);
fprintf('最终碰撞车辆: %d\n', final_collisions3);
fprintf('最终安全车辆: %d\n', num_valid3 - final_collisions3);
%%
% 获取所有安全车辆的ID（即final_flags2为false的车辆）
safe_vehicle_indices3 = valid_indices2(~final_flags3);
safe_vehicle_ids3 = car_ids2(safe_vehicle_indices3);

% 从final_data2中筛选出这些安全车辆的数据
safe_vehicles_dataset3 = final_data3(ismember(final_data3.track_id, safe_vehicle_ids3), :);

% 可选：按车辆ID和时间排序.01
safe_vehicles_dataset3 = sortrows(safe_vehicles_dataset3, {'track_id', 'time'});

% 显示结果信息
fprintf('已创建安全车辆数据集，包含 %d 辆车的 %d 条轨迹数据\n', ...
    length(safe_vehicle_ids3), height(safe_vehicles_dataset3));
%%
% 假设您的数据存储在 CSV 文件中，列名分别为 'VehicleID', 'Time', 'X', 'Y', 'Lane'  
% 读取 CSV 文件到 table 中  
trajectoryTable = data_whole2;  
  
% 初始化一个空的 table 来存储未变道的轨迹  
trajectoriesWithoutLaneChange = table;  
uniqueVehicleIDs = unique(trajectoryTable.track_id);  
  
% 遍历每辆车  
for currentVehicleID = uniqueVehicleIDs'  
    % 提取当前车辆的轨迹  
    currentVehicleTrajectory = trajectoryTable(trajectoryTable.track_id == currentVehicleID, :);  
    

    % 检查当前车辆的轨迹是否始终在车道2且未变道  
    laneChanged = false;  
    stayedInLaneTwo = all(currentVehicleTrajectory.lane_id== 1);  
    for i = 1:height(currentVehicleTrajectory) - 1  
        if currentVehicleTrajectory.lane_id(i) ~= currentVehicleTrajectory.lane_id(i + 1)  
            laneChanged = true;  
            break;  
        end  
    end  
    
    for i = 1:height(currentVehicleTrajectory) - 1  
        if (currentVehicleTrajectory.x(1)<=352400 && currentVehicleTrajectory.x(1)>=352380) || (currentVehicleTrajectory.x(end) <= 351997 && currentVehicleTrajectory.x(end) >= 352000)
            laneChanged = false;  
        else
            laneChanged = true;
            break;
        end  
    end  

    % 如果没有变道，且始终在车道2行驶，添加到结果 table 中  
    if ~laneChanged && stayedInLaneTwo  
        trajectoriesWithoutLaneChange = [trajectoriesWithoutLaneChange; currentVehicleTrajectory];  
    end  
end  
data_new=data_whole2;  
% 现在 trajectoriesWithoutLaneChange 包含了所有始终在车道2上行驶且未变道的车辆轨迹

%%
% 利用strcmp函数进行字符串比较，并将匹配到的字符串转换为数值0
    idx3 = strcmp( 'Car',data_whole2.type);
    data_whole2.Var2(idx3) = {'0'};
    idx3 = strcmp( 'Bus',data_whole2.type);
    data_whole2.Var2(idx3) = {'1'};
    idx3 = strcmp( 'Medium Vehicle',data_whole2.type);
    data_whole2.Var2(idx3) = {'2'};
    idx3 = strcmp( 'Heavy Vehicle',data_whole2.type);
    data_whole2.Var2(idx3) = {'3'};

data_whole2.type = str2double(data_whole2.type);
% 定义要筛选的列的特定值
targetValue = 3;
% 使用逻辑索引选取符合条件的行
selectedRows = (data_whole2.Var2 == targetValue);

% 选取其他两列的数据
selectedData = data_whole2(selectedRows,{'Var7', 'Var8'});
a=unique(selectedData.Var1);
figure;
for i=1:10
    selectedData1=table();
    targetValue = a(i);
    % 使用逻辑索引选取符合条件的行
    selectedRows = (selectedData.Var1 == targetValue);
    selectedData1 = selectedData(selectedRows, {'Var7', 'Var8'});
    % 绘制图形
    scatter(selectedData1.Var7, selectedData1.Var8, 'MarkerFaceColor', 'none', 'MarkerEdgeAlpha', 0.3, 'Marker', 'o','MarkerFaceColor', 'auto','DisplayName', sprintf('car %d', a(i)));
    xlabel('速度/(m/s)')
    ylabel('加速度/(m^2/s)')
    hold on

end
title('汽车速度加速度分布图')
legend;
selectedData2=table2array(selectedData2);
ab=(selectedData(:,1:2));
ab=table2array(ab);
%%  
  
data =ab;

  
% 假设 data 是一个 Nx2 的矩阵，包含我们要绘制的数据点  
data = round(data, 1);  
  
% 计算二维直方图的频数  
[N, edgesX, edgesY] = histcounts2(data(:,1), data(:,2));  
  
% 将小于5的频数设置为一个非常低的值（例如0），这样我们可以在颜色映射中为它分配白色  
N(N < 5) = 0;  
  
% 创建一个图像以表示频数  
imagesc(edgesX(1:end-1), edgesY(1:end-1), N.');  
  
% 设置坐标轴的方向以使原点在左下角  
set(gca, 'YDir', 'normal');  
  
% 添加颜色条  
colorbar;  
  
% 原始颜色映射（例如 parula）  
cmap = parula(256);  
  
% 修改颜色映射以将0值（原本小于5的频数）设置为白色  
cmap(cmap(:,1) == 0, :) = 1; % 假设颜色映射中的最低值是0（对于parula来说不是这样，这里需要调整）  
% 注意：上面的行不会正确工作，因为parula的最低值不是0。我们需要找到正确的索引来设置白色。  
% 更好的方法是直接构造一个新的颜色映射：  
cmap_new = [1 1 1; cmap(2:end,:)]; % 在顶部添加白色以用于0值（频数小于5的值）  
colormap(cmap_new); % 应用新的颜色映射  
  
% 确保0值（小于5的频数）在颜色条上显示为白色  
caxis([0, max(N(:))]); % 设置颜色轴的范围以包括0和最大值  
  
% 设置坐标轴标签  
xlabel('speed');  
ylabel('acceleration');  
  
% 添加标题  
title('2D Histogram with Color Mapping (Low Frequencies in White)');
set(gca,'ylim'=
%%
% 假设speed是速度数组，acceleration是对应的加速度数组 
ab=selectedData2;
speed = ab(:,1);  
acceleration = ab(:,2);  
  
% 找到唯一的速度值和它们的索引  
[unique_speeds, ~, speed_groups] = unique(speed);  
  
% 初始化一个结构体数组来存储结果  
results = struct('speed', unique_speeds, 'max_acceleration', zeros(length(unique_speeds), 1), 'min_acceleration', zeros(length(unique_speeds), 1));  
  
% 遍历每个速度组，找到最大和最小加速度  
for i = 1:length(unique_speeds)  
    % 找到当前速度组对应的加速度  
    group_accelerations = acceleration(speed_groups == i);  
      
    % 计算最大和最小加速度  
    results(i).max_acceleration = max(group_accelerations);  
    results(i).min_acceleration = min(group_accelerations);  
end  
  
% % 显示结果  
% for i = 1:length(results)  
%     fprintf('速度: %d, 最大加速度: %.2f, 最小加速度: %.2f\n', results(i).speed, results(i).max_acceleration, results(i).min_acceleration);  
% end
data_new2 = data_whole2;
figure


plot(data_whole2.Var5,data_whole2.Var6)

