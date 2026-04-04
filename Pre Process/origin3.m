% 假设数据集存储在 table 变量 data_new 中  
% 假设 data_new 包含以下列：'Var1' (车辆编号), 'Var5' (X 坐标), 'Var10' (Y 坐标)  
% 指定您想要绘制的累计计数车辆 
vehiclesToPlot = [143,144]; % 例如，选择了累计计数后的第1和第2辆车  
% 假设 selected_trajectories 是一个 cell 数组，每个 cell 存储一个车辆的轨迹数据，  
% 指定要查找的车辆索引
vehicleIndex1 = vehiclesToPlot(1);  % 第10辆车
vehicleIndex2 = vehiclesToPlot(2); % 第15辆车
% 提取第10和第15辆车的轨迹数据并导出到两个表
if vehicleIndex1 <= length(trajectory_cell1_ngsim)
    trajectory505 = trajectory_cell1_ngsim{vehicleIndex1};
end

if vehicleIndex2 <= length(trajectory_cell1_ngsim)
    trajectory669 = trajectory_cell1_ngsim{vehicleIndex2};
end

% 提取指定累计计数车辆的 VehicleID  
vehiclesToDraw = vehiclesToPlot; 

% 初始化两个表格，用于存储每个轨迹中最早经过 50 米和 550 米的点信息
earliest_50_data1 = table('Size', [0, 5], 'VariableTypes', {'double', 'double', 'double', 'double', 'double'}, ...
                          'VariableNames', {'TrajectoryID', 'Time', 'Distance', 'Velocity', 'Acceleration'});
earliest_550_data1 = table('Size', [0, 5], 'VariableTypes', {'double', 'double', 'double', 'double', 'double'}, ...
                          'VariableNames', {'TrajectoryID', 'Time', 'Distance', 'Velocity', 'Acceleration'});

earliest_350_data1 = table('Size', [0, 5], 'VariableTypes', {'double', 'double', 'double', 'double', 'double'}, ...
                          'VariableNames', {'TrajectoryID', 'Time', 'Distance', 'Velocity', 'Acceleration'});
% 遍历每个轨迹 cell
for i = 1:length(trajectory_cell1_ngsim)
    trajectory = trajectory_cell1_ngsim{i}; 
    % distance = trajectory(:, 3);% 提取距离列 
    % time = trajectory(:, 2);      % 提取时间列 
    % velocity = trajectory(:, 4);  % 提取速度列
    % acceleration = trajectory(:, 5);  % 提取加速度列
    % id= trajectory(:, 1);
     distance = (trajectory.y);  % 提取距离列
    time = (trajectory.globaltime);      % 提取时间列
    velocity = (trajectory.vspeed);  % 提取速度列
    acceleration = (trajectory.vacc);  % 提取加速度列
    id= trajectory.vehicleid;
    % 找到最早经过 50 米的点
    idx_50 = find(distance >= 50 & distance <= 55, 1);  % 查找距离 >= 50 的第一个索引
    if ~isempty(idx_50)
        newRow50 = {id(1), time(idx_50), distance(idx_50), velocity(idx_50), acceleration(idx_50)};
        earliest_50_data1 = [earliest_50_data1; newRow50];  % 添加新行
    else
        newRow50 = {id(1), NaN, NaN, NaN, NaN};
        earliest_50_data1 = [earliest_50_data1; newRow50];  % 添加新行
    end
    
    % 找到最早经过 550 米的点
    idx_550 = find(distance >= 595 & distance <= 600, 1);  % 查找距离 >= 550 的第一个索引
    if ~isempty(idx_550)
        newRow550 = {id(1,1), time(idx_550), distance(idx_550), velocity(idx_550), acceleration(idx_550)};
        earliest_550_data1 = [earliest_550_data1; newRow550];  % 添加新行
    else
        newRow550 = {id(1,1), NaN, NaN, NaN, NaN};
        earliest_550_data1 = [earliest_550_data1; newRow550];  % 添加新行
    end

    % 找到最早经过 350 米的点
    idx_350 = find(distance >= 300 & distance <= 305, 1);  % 查找距离 >= 550 的第一个索引
    if ~isempty(idx_350)
        newRow350 = {i, time(idx_350), distance(idx_350), velocity(idx_350), acceleration(idx_350)};
        earliest_350_data1 = [earliest_350_data1; newRow350];  % 添加新行
    else
        newRow350 = {i, NaN, NaN, NaN, NaN};
        earliest_350_data1 = [earliest_350_data1; newRow350];  % 添加新行
    end
    
end

% 显示完成信息
disp('车辆轨迹表格已导出：Vehicle10_Trajectory.csv 和 Vehicle15_Trajectory.csv');
disp('最早经过50米和550米的点数据表格已导出：Earliest50_Table.csv 和 Earliest550_Table.csv');

%%
% 假设数据集存储在 table 变量 data_new 中  
% 假设 data_new 包含以下列：'Var1' (车辆编号), 'Var5' (X 坐标), 'Var10' (Y 坐标)  
% 指定您想要绘制的累计计数车辆 
vehiclesToPlot2 = [250,281]; % 例如，选择了累计计数后的第1和第2辆车  
% 假设 selected_trajectories 是一个 cell 数组，每个 cell 存储一个车辆的轨迹数据，  
% 指定要查找的车辆索引
vehicleIndex12 = vehiclesToPlot2(1);  % 第10辆车
vehicleIndex22 = vehiclesToPlot2(2); % 第15辆车
% 提取第10和第15辆车的轨迹数据并导出到两个表
if vehicleIndex12 <= length(trajectory_cell2_ngsim)
    trajectory505_2 = trajectory_cell2_ngsim{vehicleIndex12};
end

if vehicleIndex22 <= length(trajectory_cell2_ngsim)
    trajectory669_2 = trajectory_cell2_ngsim{vehicleIndex22};
end

% 提取指定累计计数车辆的 VehicleID  
vehiclesToDraw2 = vehiclesToPlot2; 

% 初始化两个表格，用于存储每个轨迹中最早经过 50 米和 550 米的点信息
earliest_50_data2 = table('Size', [0, 5], 'VariableTypes', {'double', 'double', 'double', 'double', 'double'}, ...
                          'VariableNames', {'TrajectoryID', 'Time', 'Distance', 'Velocity', 'Acceleration'});
earliest_550_data2 = table('Size', [0, 5], 'VariableTypes', {'double', 'double', 'double', 'double', 'double'}, ...
                          'VariableNames', {'TrajectoryID', 'Time', 'Distance', 'Velocity', 'Acceleration'});

earliest_350_data2 = table('Size', [0, 5], 'VariableTypes', {'double', 'double', 'double', 'double', 'double'}, ...
                          'VariableNames', {'TrajectoryID', 'Time', 'Distance', 'Velocity', 'Acceleration'});
% 遍历每个轨迹 cell
for i = 1:length(trajectory_cell2_ngsim)
    trajectory = trajectory_cell2_ngsim{i};
    % distance = trajectory(:, 3);  % 提取距离列
    % time = trajectory(:, 2);      % 提取时间列
    % velocity = trajectory(:, 4);  % 提取速度列
    % acceleration = trajectory(:, 5);  % 提取加速度列
    % id= trajectory(:, 1);
    distance = trajectory.y;  % 提取距离列
    time = trajectory.globaltime;      % 提取时间列
    velocity = trajectory.vspeed;  % 提取速度列
    acceleration = trajectory.vacc;  % 提取加速度列
    id= trajectory.vehicleid;
    % 找到最早经过 50 米的点
    idx_50 = find(distance >= 30 & distance <= 35, 1);  % 查找距离 >= 50 的第一个索引
    if ~isempty(idx_50)
        newRow50 = {id(1), time(idx_50), distance(idx_50), velocity(idx_50), acceleration(idx_50)};
        earliest_50_data2 = [earliest_50_data2; newRow50];  % 添加新行
    else
        newRow50 = {id(1), NaN, NaN, NaN, NaN};
        earliest_50_data2 = [earliest_50_data2; newRow50];  % 添加新行
    end
    
    % 找到最早经过 550 米的点
    idx_550 = find(distance >= 595 & distance <= 600, 1);  % 查找距离 >= 550 的第一个索引
    if ~isempty(idx_550)
        newRow550 = {id(1), time(idx_550), distance(idx_550), velocity(idx_550), acceleration(idx_550)};
        earliest_550_data2 = [earliest_550_data2; newRow550];  % 添加新行
    else
        newRow550 = {id(1), NaN, NaN, NaN, NaN};
        earliest_550_data2 = [earliest_550_data2; newRow550];  % 添加新行
    end

    % 找到最早经过 350 米的点
    idx_350 = find(distance >= 300 & distance <= 305, 1);  % 查找距离 >= 550 的第一个索引
    if ~isempty(idx_350)
        newRow350 = {i, time(idx_350), distance(idx_350), velocity(idx_350), acceleration(idx_350)};
        earliest_350_data2 = [earliest_350_data2; newRow350];  % 添加新行
    else
        newRow350 = {i, NaN, NaN, NaN, NaN};
        earliest_350_data2 = [earliest_350_data2; newRow350];  % 添加新行
    end
    
end

% 显示完成信息
disp('车辆轨迹表格已导出：Vehicle10_Trajectory.csv 和 Vehicle15_Trajectory.csv');
disp('最早经过50米和550米的点数据表格已导出：Earliest50_Table.csv 和 Earliest550_Table.csv');
%% 寻找换道车辆的车辆cell（一般不常用）
vehicleID = 5593;  % 目标车辆ID
vehicleIndex = NaN;  % 初始化索引，默认值为NaN

% 遍历所有轨迹
for i = 1:length(trajectory_cell2_ngsim)
    trajectory = trajectory_cell2_ngsim{i};
    id = table2array(trajectory(:, 1));  % 获取车辆ID列
    
    % 检查是否有匹配的车辆ID
    if any(id == vehicleID)
        vehicleIndex = i;  % 找到匹配的轨迹
        break;  % 找到后退出循环
    end
end

if isnan(vehicleIndex)
    disp('车辆ID为5354的轨迹未找到');
else
    disp(['车辆ID为5354的轨迹位于 trajectory_cell1 的第 ', num2str(vehicleIndex), ' 个 cell']);
end

%% 筛选数据集生成一个新的数据集进行验证测算
% 假设你已经创建了 earliest_50_data2 和 earliest_550_data2 表
% 筛选 earliest_550_data2 和 earliest_50_data2 时间都不是 NaN 的车辆 ID
valid_50_data2 = earliest_50_data2(~isnan(earliest_50_data2.Time), :);  % 筛选时间不为 NaN 的行
valid_550_data2 = earliest_550_data2(~isnan(earliest_550_data2.Time), :);  % 筛选时间不为 NaN 的行

% 取出 valid_50_data2 和 valid_550_data2 中车辆的 TrajectoryID
valid_vehicles_50_550_2 = intersect(valid_50_data2.TrajectoryID, valid_550_data2.TrajectoryID);
valid_vehicles_50_550_2 = [valid_vehicles_50_550_2;common_ids];
valid_vehicles_50_550_2 = unique(valid_vehicles_50_550_2);
valid_vehicles_50_550_2 = sortrows(valid_vehicles_50_550_2);
% 筛选 earliest_550_data1 和 earliest_50_data1 时间都不是 NaN 的车辆 ID
valid_50_data1 = earliest_50_data1(~isnan(earliest_50_data1.Time), :);  % 筛选时间不为 NaN 的行
valid_550_data1 = earliest_550_data1(~isnan(earliest_550_data1.Time), :);  % 筛选时间不为 NaN 的行

% 取出 valid_50_data1 和 valid_550_data1 中车辆的 TrajectoryID
valid_vehicles_50_550_1 = intersect(valid_50_data1.TrajectoryID, valid_550_data1.TrajectoryID);
valid_vehicles_50_550_1 = [valid_vehicles_50_550_1;common_ids];
valid_vehicles_50_550_1 = unique(valid_vehicles_50_550_1);
valid_vehicles_50_550_1 = sortrows(valid_vehicles_50_550_1);
% 显示筛选结果
disp('earliest_550_data2 和 earliest_50_data2 时间都不是 NaN 的车辆 ID:');
disp(valid_vehicles_50_550_2);

disp('earliest_550_data1 和 earliest_50_data1 时间都不是 NaN 的车辆 ID:');
disp(valid_vehicles_50_550_1);
%%
% 假设 valid_vehicles_50_550_1 和 valid_vehicles_50_550_2 是两个有效车辆 ID 的数组
% 对 selected_trajectories1 进行筛选
valid_trajectories1 = {}; % 用来存储筛选后的有效轨迹
for i = 1:length(trajectory_cell2_ngsim)
    % 提取当前轨迹的车辆 ID 列
    current_ids1 = trajectory_cell2_ngsim{i}(:, 1); 
    
    % 检查当前轨迹的 ID 是否在 valid_vehicles_50_550_1 中
    if any(ismember(current_ids1, valid_vehicles_50_550_1))
        % 如果该轨迹的车辆 ID 存在于 valid_vehicles_50_550_1 中，保留该轨迹
        valid_trajectories1{end+1} = trajectory_cell2_ngsim{i};
    end
end

% 删除空白的 cell 数组
selected_trajectories1_new = valid_trajectories1;

% 对 selected_trajectories2 进行筛选
valid_trajectories2 = {}; % 用来存储筛选后的有效轨迹
for i = 1:length(trajectory_cell2_ngsim)
    % 提取当前轨迹的车辆 ID 列
    current_ids2 = trajectory_cell2_ngsim{i}(:, 1); 
    
    % 检查当前轨迹的 ID 是否在 valid_vehicles_50_550_2 中
    if any(ismember(current_ids2, valid_vehicles_50_550_2))
        % 如果该轨迹的车辆 ID 存在于 valid_vehicles_50_550_2 中，保留该轨迹
        valid_trajectories2{end+1} = trajectory_cell2_ngsim{i};
    end
end

% 删除空白的 cell 数组
selected_trajectories2_new = valid_trajectories2;

% 显示结果
disp('已剔除无效轨迹，并筛选掉空白的 cell 数组');
%%
% 假设 common_ids 是之前提取的公共 ID

% 遍历 selected_trajectories1 中的每个 cell
for i = 1:length(selected_trajectories1_new)
    % 提取当前轨迹的车辆 ID 列
    current_ids1 = selected_trajectories1_new{i}(:, 1); 
    
    % 检查是否有 common_id 存在于当前轨迹的车辆 ID 中
    for j = 1:length(common_ids)
        if any(current_ids1 == common_ids(j))
            % 如果当前轨迹包含 common_id，将该轨迹所有 ID 设置为 common_id
            selected_trajectories1_new{i}(:, 1) = common_ids(j);
            break; % 找到 common_id 后跳出循环
        end
    end
end

% 对 selected_trajectories2 做同样的操作
for i = 1:length(selected_trajectories2_new)
    % 提取当前轨迹的车辆 ID 列
    current_ids2 = selected_trajectories2_new{i}(:, 1);
    
    % 检查是否有 common_id 存在于当前轨迹的车辆 ID 中
    for j = 1:length(common_ids)
        if any(current_ids2 == common_ids(j))
            % 如果当前轨迹包含 common_id，将该轨迹所有 ID 设置为 common_id
            selected_trajectories2_new{i}(:, 1) = common_ids(j);
            break; % 找到 common_id 后跳出循环
        end
    end
end

% 显示结果
disp('已更新轨迹 ID');
%%

for i = 1:length(selected_trajectories1_new)
    % 提取当前轨迹的车辆 ID 列
    current_ids1 = selected_trajectories1_new{i}(:, 1); 
    
    % 获取当前轨迹中的唯一 ID
    unique_ids = unique(current_ids1);
    
    % 如果轨迹中有两个或更多不同的 ID
    if length(unique_ids) > 1
        % 随机选择其中一个 ID
        selected_id = unique_ids(randi(length(unique_ids)));
        
        % 将该轨迹所有车辆 ID 更新为所选的 ID
        selected_trajectories1_new{i}(:, 1) = selected_id;
    end
end

% 对 selected_trajectories2 做同样的操作
for i = 1:length(selected_trajectories2_new)
    % 提取当前轨迹的车辆 ID 列
    current_ids2 = selected_trajectories2_new{i}(:, 1);
    
    % 获取当前轨迹中的唯一 ID
    unique_ids = unique(current_ids2);
    
    % 如果轨迹中有两个或更多不同的 ID
    if length(unique_ids) > 1
        % 随机选择其中一个 ID
        selected_id = unique_ids(randi(length(unique_ids)));
        
        % 将该轨迹所有车辆 ID 更新为所选的 ID
        selected_trajectories2_new{i}(:, 1) = selected_id;
    end
end

% 显示结果
disp('轨迹 ID 更新完成');

% % 遍历 selected_trajectories1 中的每个 cell
% for i = 1:length(trajectory_cell2_ngsim)
%     % 提取当前轨迹的车辆 ID 列
%     current_ids1 = trajectory_cell2_ngsim{i}(:, 1); 
% 
%     % 获取当前轨迹中的唯一 ID
%     unique_ids = unique(current_ids1);
% 
%     % 如果轨迹中有两个或更多不同的 ID
%     if length(unique_ids) > 1
%         % 随机选择其中一个 ID
%         selected_id = unique_ids(randi(length(unique_ids)));
% 
%         % 将该轨迹所有车辆 ID 更新为所选的 ID
%         trajectory_cell2_ngsim{i}(:, 1) = selected_id;
%     end
% end
% 
% % 对 selected_trajectories2 做同样的操作
% for i = 1:length(trajectory_cell2_ngsim)
%     % 提取当前轨迹的车辆 ID 列
%     current_ids2 = trajectory_cell2_ngsim{i}(:, 1);
% 
%     % 获取当前轨迹中的唯一 ID
%     unique_ids = unique(current_ids2);
% 
%     % 如果轨迹中有两个或更多不同的 ID
%     if length(unique_ids) > 1
%         % 随机选择其中一个 ID
%         selected_id = unique_ids(randi(length(unique_ids)));
% 
%         % 将该轨迹所有车辆 ID 更新为所选的 ID
%         trajectory_cell2_ngsim{i}(:, 1) = selected_id;
%     end
% end
% 
% % 显示结果
% disp('轨迹 ID 更新完成');
% 遍历 selected_trajectories1 中的每个 cell
%%
% 假设 common_ids 是之前提取的公共 ID
% selected_trajectories1 = selected_trajectories_beiyong1;
% selected_trajectories2 = selected_trajectories_beiyong2;
% 第一步：先处理有 common_ids 的轨迹
for i = 1:length(selected_trajectories1_new)
    current_ids1 = selected_trajectories1_new{i}(:, 1); 
    for j = 1:length(common_ids)
        if any(current_ids1 == common_ids(j))
            selected_trajectories1_new{i}(:, 1) = common_ids(j);
            break;
        end
    end
end

for i = 1:length(selected_trajectories2_new)
    current_ids2 = selected_trajectories2_new{i}(:, 1);
    for j = 1:length(common_ids)
        if any(current_ids2 == common_ids(j))
            selected_trajectories2_new{i}(:, 1) = common_ids(j);
            break;
        end
    end
end

% 第二步：收集所有非公共轨迹的 ID
all_non_common_ids = [];
all_trajectories = [selected_trajectories1_new, selected_trajectories2_new];

for i = 1:length(all_trajectories)
    current_id = all_trajectories{i}(1, 1);
    if ~ismember(current_id, common_ids)
        all_non_common_ids = [all_non_common_ids; current_id];
    end
end

% 第三步：找出重复的 ID
unique_ids = unique(all_non_common_ids);
used_ids = common_ids; % 已使用的 ID（包括公共 ID）
new_id = max([common_ids; all_non_common_ids]) + 10000; % 从最大 ID+10000 开始

% 第四步：处理重复 ID
for i = 1:length(unique_ids)
    current_id = unique_ids(i);
    
    % 如果这个 ID 在非公共 ID 中重复出现
    if sum(all_non_common_ids == current_id) > 1
        found_first = false; % 标记是否找到第一个出现的
        
        % 处理 selected_trajectories1
        for j = 1:length(selected_trajectories1_new)
            traj_id = selected_trajectories1_new{j}(1, 1);
            
            if traj_id == current_id && ~ismember(traj_id, common_ids)
                if ~found_first
                    % 第一个出现的，保留原ID
                    found_first = true;
                    used_ids = [used_ids; current_id];
                else
                    % 后续出现的，分配新 ID
                    while ismember(new_id, used_ids)
                        new_id = new_id + 1
                    end
                    selected_trajectories1_new{j}(:, 1) = new_id;
                    used_ids = [used_ids; new_id];
                    new_id = new_id + 1;
                end
            end
        end
        
        % 处理 selected_trajectories2
        for j = 1:length(selected_trajectories2_new)
            traj_id = selected_trajectories2_new{j}(1, 1);
            
            if traj_id == current_id && ~ismember(traj_id, common_ids)
                if ~found_first
                    % 第一个出现的，保留原ID
                    found_first = true;
                    used_ids = [used_ids; current_id];
                else
                    % 后续出现的，分配新 ID
                    while ismember(new_id, used_ids)
                        new_id = new_id + 1
                    end
                    selected_trajectories2_new{j}(:, 1) = new_id;
                    used_ids = [used_ids; new_id];
                    new_id = new_id + 1;
                end
            end
        end
    end
end

disp('轨迹 ID 更新完成');
%%
% 假设 common_ids 是之前提取的公共 ID

% 函数：检查并确保数据集内部的ID唯一性
function updated_trajectories = ensureUniqueIDs(trajectories, common_ids)
    updated_trajectories = trajectories;
    
    % 收集所有轨迹的ID信息
    all_ids = [];
    trajectory_info = [];
    
    % 第一遍：收集所有ID信息
    for i = 1:length(updated_trajectories)
        if ~isempty(updated_trajectories{i})
            current_id = updated_trajectories{i}(1, 1); % 取第一个点的ID作为该轨迹的ID
            all_ids = [all_ids; current_id];
            trajectory_info = [trajectory_info; i, current_id];
        end
    end
    
    % 找出重复的ID（排除common_ids）
    unique_ids = unique(all_ids);
    duplicate_ids = [];
    
    for i = 1:length(unique_ids)
        current_id = unique_ids(i);
        % 如果是common_id，跳过
        % if any(common_ids == current_id)
        %     continue;
        % end

        % 统计该ID出现的次数
        count = sum(all_ids == current_id);
        if count > 1
            duplicate_ids = [duplicate_ids; current_id];
        end
    end
    
    % 为需要重命名的轨迹生成新的唯一ID
    if ~isempty(duplicate_ids)
        % 找到当前最大的ID
        if ~isempty(all_ids)
            max_id = max(all_ids);
        else
            max_id = 0;
        end
        
        % 处理每个重复的ID
        for i = 1:length(duplicate_ids)
            current_dup_id = duplicate_ids(i);
            
            % 找到所有使用这个重复ID的轨迹（除了第一个）
            dup_indices = find(all_ids == current_dup_id);
            
            % 第一个轨迹保持原ID，其他的重新分配
            for j = 2:length(dup_indices)
                trajectory_idx = dup_indices(j);
                original_idx = trajectory_info(trajectory_idx, 1);
                
                % 生成新的唯一ID
                max_id = max_id + 1;
                new_id = max_id;
                
                % 更新轨迹ID
                updated_trajectories{original_idx}(:, 1) = new_id;
                
                fprintf('轨迹 %d 的ID从 %d 更改为 %d\n', original_idx, current_dup_id, new_id);
            end
        end
    end
end

% 对两个数据集分别进行处理
fprintf('处理 selected_trajectories1...\n');
selected_trajectories1_new = ensureUniqueIDs(selected_trajectories1_new, common_ids);

fprintf('处理 selected_trajectories2...\n');
selected_trajectories2_new = ensureUniqueIDs(selected_trajectories2_new, common_ids);

% 验证结果
fprintf('\n验证结果:\n');

% 检查selected_trajectories1的ID唯一性
ids1 = [];
for i = 1:length(selected_trajectories1_new)
    if ~isempty(selected_trajectories1_new{i})
        current_id = selected_trajectories1_new{i}(1, 1);
        ids1 = [ids1; current_id];
    end
end
fprintf('selected_trajectories1 唯一ID数量: %d, 总轨迹数: %d\n', length(unique(ids1)), length(ids1));

% 检查selected_trajectories2的ID唯一性
ids2 = [];
for i = 1:length(selected_trajectories2_new)
    if ~isempty(selected_trajectories2_new{i})
        current_id = selected_trajectories2_new{i}(1, 1);
        ids2 = [ids2; current_id];
    end
end
fprintf('selected_trajectories2 唯一ID数量: %d, 总轨迹数: %d\n', length(unique(ids2)), length(ids2));

fprintf('ID唯一性处理完成！\n');
%%
% 初始化一个空数组来存储所有轨迹数据
data_whole_pingjie2_new = [];

% 遍历每个cell
for i = 1:length(trajectory_cell2_ngsim)
    % 提取当前cell的轨迹数据并转换为double
    current_traj = double(trajectory_cell2_ngsim{i});
    
    % 按行拼接
    data_whole_pingjie2_new = [data_whole_pingjie2_new; current_traj];
end

data_whole_pingjie2_new = data_whole_pingjie2_new;

% 显示结果信息
fprintf('拼接完成！\n');
fprintf('原始cell数量: %d\n', length(trajectory_cell2_ngsim));
fprintf('最终数据维度: %d行 × %d列\n', size(data_whole_pingjie2_new, 1), size(data_whole_pingjie2_new, 2));

% 初始化一个空数组来存储所有轨迹数据
data_whole_pingjie1_new = [];

% 遍历每个cell
for i = 1:length(trajectory_cell2_ngsim)
    % 提取当前cell的轨迹数据并转换为double
    current_traj = double(trajectory_cell2_ngsim{i});
    
    % 按行拼接
    data_whole_pingjie1_new = [data_whole_pingjie1_new; current_traj];
end

data_whole_pingjie1_new = data_whole_pingjie1_new;

% 显示结果信息
fprintf('拼接完成！\n');
fprintf('原始cell数量: %d\n', length(trajectory_cell2_ngsim));
fprintf('最终数据维度: %d行 × %d列\n', size(data_whole_pingjie1_new, 1), size(data_whole_pingjie1_new, 2));