% 绘制两辆特定车的轨迹  
figure;  
hold on; 
% trajectory505_2 = selected_trajectories2{vehiclesToDraw2(1)};
% trajectory669_2 = selected_trajectories2{vehiclesToDraw2(2)};
% plot(trajectory505_2(:,2), trajectory505_2(:,3), 'r-', 'LineWidth', 2);  
% plot(trajectory669_2(:,2), trajectory669_2(:,3), 'r-', 'LineWidth', 2);
plot(trajectory505_2.globaltime, trajectory505_2.y, 'r-', 'LineWidth', 2);  
plot(trajectory669_2.globaltime, trajectory669_2.y, 'r-', 'LineWidth', 2);
% 获取车辆编号对应的时间范围
time_min550 = earliest_550_data2.Time(vehiclesToDraw2(1));
time_max550 = earliest_550_data2.Time(vehiclesToDraw2(2));

% time_min450 = earliest_450_data.Time(vehiclesToDraw(1));
% time_max450 = earliest_450_data.Time(vehiclesToDraw(2));
% 
time_min350 = earliest_350_data2.Time(vehiclesToDraw2(1));
time_max350 = earliest_350_data2.Time(vehiclesToDraw2(2));

time_min50 = earliest_50_data2.Time(vehiclesToDraw2(1));
time_max50 = earliest_50_data2.Time(vehiclesToDraw2(2));

% 筛选时间范围内的车辆经过 550m 的轨迹点
vehiclesInRangeAt550m2 = earliest_550_data2(earliest_550_data2.Time >= time_min550 & earliest_550_data2.Time <= time_max550, :);
% 获取筛选后的数据的索引
indicesInOriginalData550m2 = find(earliest_550_data2.Time >= time_min550 & earliest_550_data2.Time <= time_max550);
% 对筛选后的数据按照时间排序
vehiclesInRangeAt550m2 = sortrows(vehiclesInRangeAt550m2, "Time");

% 绘制这些轨迹点
scatter(vehiclesInRangeAt550m2.Time, vehiclesInRangeAt550m2.Distance, 'MarkerFaceColor', [1 0 1], 'Marker', '*');

% 筛选时间范围内的车辆经过 50m 的轨迹点
vehiclesInRangeAt50m2 = earliest_50_data2(earliest_50_data2.Time >= time_min50 & earliest_50_data2.Time <= time_max50, :);
% 获取筛选后的数据的索引
indicesInOriginalData50m2 = find(earliest_50_data2.Time >= time_min50 & earliest_50_data2.Time <= time_max50);
% 对筛选后的数据按照时间排序
vehiclesInRangeAt50m2 = sortrows(vehiclesInRangeAt50m2, "Time");

% 筛选时间范围内的车辆经过 350m 的轨迹点
vehiclesInRangeAt350m2 = earliest_350_data2(earliest_350_data2.Time >= time_min350 & earliest_350_data2.Time <= time_max350, :);
% 获取筛选后的数据的索引
indicesInOriginalData350m2 = find(earliest_350_data2.Time >= time_min350 & earliest_350_data2.Time <= time_max350);
% 对筛选后的数据按照时间排序
vehiclesInRangeAt350m2 = sortrows(vehiclesInRangeAt350m2, "Time");

% % 绘制这些轨迹点


% 绘制这些轨迹点
scatter(vehiclesInRangeAt50m2.Time, vehiclesInRangeAt50m2.Distance, 'MarkerFaceColor', [1 0 1], 'Marker', '*');
% 给定的斜率  
slope = -7.7157;
% slope =-5.531255714089974e-04;
% 定义浅蓝色的 RGBA 值  

lightBlueColor = [0.6 0.8 1.0 0.3]; % RGBA 格式：[红 绿 蓝 透明度]

% 初始化存储斜率和截距的数组  

shockwave_slopes = [];  

shockwave_intercepts = []; 

% 绘制通过 Var10 等于 1100 的每个点的线  
for i = 1:height(vehiclesInRangeAt550m2)  
    % 从轨迹点数据中提取 x 和 y（
    x_trajectory = vehiclesInRangeAt550m2.Time(i);
    y_trajectory = vehiclesInRangeAt550m2.Distance(i);

    % 使用直线方程 y = ax + b，计算截距 b
    b = y_trajectory - slope * x_trajectory;
    
    % 保存斜率和截距  
    shockwave_slopes(end+1) = slope; % 斜率 a 是给定的，所以对于每条线都是一样的  
    shockwave_intercepts(end+1) = b; % 截距 b 是根据每个轨迹点计算出来的，所以是不同的

    % 根据 y=0 和 y=1300 以及斜率 a，计算对应的 x 值
    x_at_y0 = -b / slope; % 当 y = 0 时的 x 值
    x_at_y1300 = (1300 - b) / slope; % 当 y = 1300 时的 x 值

    % 绘制虚线
    plot([x_at_y0, x_at_y1300], [0, 1300],'--','Color', lightBlueColor, 'LineWidth', 1.5);
end  
  
% 添加图例和坐标轴标签  
legend({'Vehicle 505', 'Vehicle 669', 'Vehicles 505-669 at 1100m'});  
xlabel('时间(s)');  
ylabel('空间 (m)');  
title('Vehicle Trajectories and Points at 1100m');  
  
% % 设置Y轴方向为从大到小  
% set(gca, 'YDir', 'reverse');  
  
% 设置图形界限以适应所有数据点  
allX = [trajectory505_2.globaltime; trajectory669_2.globaltime; vehiclesInRangeAt550m2.Time];  
allY = [trajectory505_2.y; trajectory669_2.y;vehiclesInRangeAt550m2.Distance];  
% allX = [trajectory505_2(:,2); trajectory669_2(:,2); vehiclesInRangeAt550m2.Time];  
% allY = [trajectory505_2(:,3); trajectory669_2(:,3);vehiclesInRangeAt550m2.Distance];  
xlim([min(allX) max(allX)]);  
ylim([min(allY) max(allY)]);  
  
hold off;
%%
% 初始化存储不变点和变化点的矩阵，第三列记录来源
unchanging_points2 = [];
changing_points2 = [];

% 获取两个数据集的 id
ids_50m2 = vehiclesInRangeAt50m2.TrajectoryID;
ids_550m2 = vehiclesInRangeAt550m2.TrajectoryID;

% 创建一个新的图形
figure;
hold on;

% % 绘制初始的车辆轨迹
% plot(trajectory505_2(:,2), trajectory505_2(:,3), 'r-', 'LineWidth', 2);  
% plot(trajectory669_2(:,2), trajectory669_2(:,3), 'r-', 'LineWidth', 2);

plot(trajectory505_2.globaltime, trajectory505_2.y, 'r-', 'LineWidth', 2);  
plot(trajectory669_2.globaltime, trajectory669_2.y, 'r-', 'LineWidth', 2);

% 遍历 50m 轨迹数据
for i = 1:height(vehiclesInRangeAt50m2)
    % 获取当前车辆的 id 和时间、距离
    id_50m2 = vehiclesInRangeAt50m2.TrajectoryID(i);
    time_50m2 = vehiclesInRangeAt50m2.Time(i);
    distance_50m2 = vehiclesInRangeAt50m2.Distance(i);
    
    % 检查是否在 550m 数据中存在相同的 id
    idx_550m2 = find(ids_550m2 == id_50m2);
    
    if ~isempty(idx_550m2) % 如果 50m 数据集中的 id 也存在于 550m 数据集
        % 绘制为蓝色点
        scatter(time_50m2, distance_50m2, 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'b', 'Marker', '*');
        % 保存该 id 为不变点，并标记来源为50m
        unchanging_points2 = [unchanging_points2; id_50m2];
    else
        % if any(id_50m2 == common_ids)
        % 绘制为红色点
        scatter(time_50m2, distance_50m2, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r', 'Marker', '*');
        % 保存该 id 为变化点，并标记来源为50m
        changing_points2 = [changing_points2; id_50m2,1];
        % end
    end
end

% 遍历 550m 轨迹数据
for i = 1:height(vehiclesInRangeAt550m2)
    % 获取当前车辆的 id 和时间、距离
    id_550m2 = vehiclesInRangeAt550m2.TrajectoryID(i);
    time_550m2 = vehiclesInRangeAt550m2.Time(i);
    distance_550m2 = vehiclesInRangeAt550m2.Distance(i);
    
    % 检查是否在 50m 数据中存在相同的 id
    idx_50m2 = find(ids_50m2 == id_550m2);
    
    if isempty(idx_50m2) % 如果 550m 数据集中的 id 不存在于 50m 数据集
        % if any(id_550m2 == common_ids)
        % 绘制为红色点
        scatter(time_550m2, distance_550m2, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r', 'Marker', '*');
        % 保存该 id 为变化点，并标记来源为550m
        changing_points2 = [changing_points2; id_550m2, 2];
        % end
    else
        % 绘制为蓝色点
        scatter(time_550m2, distance_550m2, 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'b', 'Marker', '*');
    
    end
end

% 添加图例和坐标轴标签
legend({'Vehicle 505', 'Vehicle 669', 'Vehicles 505-669 at 1100m'});
xlabel('时间(s)');
ylabel('空间 (m)');
title('Vehicle Trajectories and Points at 1100m');

% 设置图形界限以适应所有数据点
% allX = [trajectory505_2(:,2); trajectory669_2(:,2); vehiclesInRangeAt550m2.Time];  
% allY = [trajectory505_2(:,3); trajectory669_2(:,3);vehiclesInRangeAt550m2.Distance];  
allX = [trajectory505_2.globaltime; trajectory669_2.globaltime; vehiclesInRangeAt550m1.Time; vehiclesInRangeAt50m1.Time];
allY = [trajectory505_2.y; trajectory669_2.y; vehiclesInRangeAt550m1.Distance; vehiclesInRangeAt50m1.Distance];
xlim([min(allX) max(allX)]);  
ylim([min(allY) max(allY)]);  
  

hold off;
common_changing_points = intersect(changing_points(:,1),changing_points2(:,1));
%%
changing_points2_new=[];
for i = 1:size(changing_points2,1)
    if any(changing_points2(i,1)==common_changing_points)
        changing_points2_new = [changing_points2_new;changing_points2(i,:)];
    end
end
changing_points2 = changing_points2_new;
[sorted_points2, index2] = sort(changing_points2(:, 1));
% 使用排序的索引重新排列整个矩阵
sorted_changing_points2 = changing_points2(index2, :);
changing_points2 = sorted_changing_points2;
%%
changing_points_new=[];
for i = 1:size(changing_points,1)
    if any(changing_points(i,1)==common_changing_points)
        changing_points_new = [changing_points_new;changing_points(i,:)];
    end
end
changing_points = changing_points_new;
% 使用 sort 函数按第一列排序
[sorted_points, index] = sort(changing_points(:, 1));
% 使用排序的索引重新排列整个矩阵
sorted_changing_points = changing_points(index, :);
changing_points = sorted_changing_points;
%%
% changing_points_whole =[];
changing_points_whole = [changing_points_whole;common_changing_points];
%%
% 初始化存储时间差的矩阵
T2 = [];

% 遍历 50m 轨迹数据
for i = 1:height(vehiclesInRangeAt50m2)
    % 获取当前车辆的 id 和时间
    id_50m2 = vehiclesInRangeAt50m2.TrajectoryID(i);
    time_50m2 = vehiclesInRangeAt50m2.Time(i);
    
    % 检查是否在 550m 数据中存在相同的 id
    idx_550m2 = find(ids_550m2 == id_50m2);
    
    if ~isempty(idx_550m2) % 如果 50m 数据集中的 id 也存在于 550m 数据集
        % 获取 550m 数据中的时间
        time_550m2 = vehiclesInRangeAt550m2.Time(idx_550m2);
        
        % 计算时间差
        time_diff = abs(time_550m2 - time_50m2);
        
        % 将车辆 id 和对应的时间差存储到矩阵 T 中
        T2 = [T2; id_50m2, time_diff];
    end
end

% 打印结果
disp(T2);
%%
% 初始化存储不变点和变化点的矩阵
unchanging_points2 = [];

% 获取两个数据集的 id
ids_50m2 = vehiclesInRangeAt50m2.TrajectoryID;
ids_550m2 = vehiclesInRangeAt550m2.TrajectoryID;

% 创建一个新的图形
figure;
hold on;

% 绘制初始的车辆轨迹
% plot(trajectory505_2(:,2), trajectory505_2(:,3), 'r-', 'LineWidth', 2);  
% plot(trajectory669_2(:,2), trajectory669_2(:,3), 'r-', 'LineWidth', 2);
plot(trajectory505_2.globaltime, trajectory505_2.y, 'r-', 'LineWidth', 2);  
plot(trajectory669_2.globaltime, trajectory669_2.y, 'r-', 'LineWidth', 2);
% 遍历 50m 轨迹数据
for i = 1:height(vehiclesInRangeAt50m2)
    % 获取当前车辆的 id 和时间、距离、速度、加速度
    id_50m2 = vehiclesInRangeAt50m2.TrajectoryID(i);
    time_50m2 = vehiclesInRangeAt50m2.Time(i);
    distance_50m2 = vehiclesInRangeAt50m2.Distance(i);
    velocity_50m2 = vehiclesInRangeAt50m2.Velocity(i);
    acceleration_50m2 = vehiclesInRangeAt50m2.Acceleration(i);
    
    % 检查是否在 550m 数据中存在相同的 id
    idx_550m2 = find(ids_550m2 == id_50m2);
    
    if ~isempty(idx_550m2) % 如果 50m 数据集中的 id 也存在于 550m 数据集
        % 绘制为蓝色点
        scatter(time_50m2, distance_50m2, 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'b', 'Marker', '*');
        % 保存该 id 为不变点，并标记来源为50m
        unchanging_points2 = [unchanging_points2; id_50m2];
    else
        % 如果 50m 数据集中的 id 不在 550m 数据集
        % 绘制为红色点
        scatter(time_50m2, distance_50m2, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r', 'Marker', '*');
        
        % 计算前后点的时间差比例，生成相应的点
        idx_prev = max(i - 1, 1); % 获取前一个点的索引
        idx_next = min(i + 1, height(vehiclesInRangeAt50m2)); % 获取后一个点的索引
        
        time_prev = vehiclesInRangeAt50m2.Time(idx_prev);
        time_next = vehiclesInRangeAt50m2.Time(idx_next);
        
        % 时间差比例
        time_diff = time_next - time_prev;
        time_ratio = (time_50m2 - time_prev) / time_diff;
        
        % 在 550m 处生成相应的点
        idx_550m2_prev = find(ids_550m2 == vehiclesInRangeAt50m2.TrajectoryID(idx_prev));
        idx_550m2_next = find(ids_550m2 == vehiclesInRangeAt50m2.TrajectoryID(idx_next));
        
        % 如果前后点都没有对应的id，则需要继续查找前后点，直到找到为止
        while isempty(idx_550m2_prev) || isempty(idx_550m2_next)
            if isempty(idx_550m2_prev) && idx_prev > 1
                idx_prev = idx_prev - 1; % 向前查找
                idx_550m2_prev = find(ids_550m2 == vehiclesInRangeAt50m2.TrajectoryID(idx_prev));
            end
            if isempty(idx_550m2_next) && idx_next < height(vehiclesInRangeAt50m2)
                idx_next = idx_next + 1; % 向后查找
                idx_550m2_next = find(ids_550m2 == vehiclesInRangeAt50m2.TrajectoryID(idx_next));
            end
        end
        
        % 确保找到前后点时进行插值
        if ~isempty(idx_550m2_prev) && ~isempty(idx_550m2_next)
            % 获取550m的前后点时间
            time_550m2_prev = vehiclesInRangeAt550m2.Time(idx_550m2_prev);
            time_550m2_next = vehiclesInRangeAt550m2.Time(idx_550m2_next);
            
            % 生成550m的点
            time_new_550m2 = time_550m2_prev + time_ratio * (time_550m2_next - time_550m2_prev);
            
            % 使用线性插值生成新点的距离、速度和加速度
            distance_new_550m2 = interp1(vehiclesInRangeAt550m2.Time, vehiclesInRangeAt550m2.Distance, time_new_550m2, 'linear');
            velocity_new_550m2 = interp1(vehiclesInRangeAt550m2.Time, vehiclesInRangeAt550m2.Velocity, time_new_550m2, 'linear');
            acceleration_new_550m2 = interp1(vehiclesInRangeAt550m2.Time, vehiclesInRangeAt550m2.Acceleration, time_new_550m2, 'linear');
            
            % 将新点加入到vehiclesInRangeAt550m2集合中
            vehiclesInRangeAt550m2 = [vehiclesInRangeAt550m2; {id_50m2, time_new_550m2, distance_new_550m2, velocity_new_550m2, acceleration_new_550m2}];
            
            % 同时将新点添加到unchanging_points2
            unchanging_points2 = [unchanging_points2; id_50m2];
        end
    end
end

% 遍历 550m 轨迹数据
for i = 1:height(vehiclesInRangeAt550m2)
    % 获取当前车辆的 id 和时间、距离、速度、加速度
    id_550m2 = vehiclesInRangeAt550m2.TrajectoryID(i);
    time_550m2 = vehiclesInRangeAt550m2.Time(i);
    distance_550m2 = vehiclesInRangeAt550m2.Distance(i);
    velocity_550m2 = vehiclesInRangeAt550m2.Velocity(i);
    acceleration_550m2 = vehiclesInRangeAt550m2.Acceleration(i);
    
    % 检查是否在 50m 数据中存在相同的 id
    idx_50m2 = find(ids_50m2 == id_550m2);
    
    if isempty(idx_50m2) % 如果 550m 数据集中的 id 不存在于 50m 数据集
        % 如果 550m 数据集中的 id 不在 50m 数据集
        % 绘制为红色点
        scatter(time_550m2, distance_550m2, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r', 'Marker', '*');
        
        % 计算前后点的时间差比例，生成相应的点
        idx_prev = max(i - 1, 1); % 获取前一个点的索引
        idx_next = min(i + 1, height(vehiclesInRangeAt550m2)); % 获取后一个点的索引
        
        time_prev = vehiclesInRangeAt550m2.Time(idx_prev);
        time_next = vehiclesInRangeAt550m2.Time(idx_next);
        
        % 时间差比例
        time_diff = time_next - time_prev;
        time_ratio = (time_550m2 - time_prev) / time_diff;
        
        % 在 50m 处生成相应的点
        idx_50m2_prev = find(ids_50m2 == vehiclesInRangeAt550m2.TrajectoryID(idx_prev));
        idx_50m2_next = find(ids_50m2 == vehiclesInRangeAt550m2.TrajectoryID(idx_next));
        
        % 如果前后点都没有对应的id，则需要继续查找前后点，直到找到为止
        while isempty(idx_50m2_prev) || isempty(idx_50m2_next)
            if isempty(idx_50m2_prev) && idx_prev > 1
                idx_prev = idx_prev - 1; % 向前查找
                idx_50m2_prev = find(ids_50m2 == vehiclesInRangeAt550m2.TrajectoryID(idx_prev));
            end
            if isempty(idx_50m2_next) && idx_next < height(vehiclesInRangeAt550m2)
                idx_next = idx_next + 1; % 向后查找
                idx_50m2_next = find(ids_50m2 == vehiclesInRangeAt550m2.TrajectoryID(idx_next));
            end
        end
        
        % 确保找到前后点时进行插值
        if ~isempty(idx_50m2_prev) && ~isempty(idx_50m2_next)
            % 获取50m的前后点时间
            time_50m2_prev = vehiclesInRangeAt50m2.Time(idx_50m2_prev);
            time_50m2_next = vehiclesInRangeAt50m2.Time(idx_50m2_next);
            
            % 生成50m的点
            time_new_50m2 = time_50m2_prev + time_ratio * (time_50m2_next - time_50m2_prev);
            
            % 使用线性插值生成新点的距离、速度和加速度
            distance_new_50m2 = interp1(vehiclesInRangeAt50m2.Time, vehiclesInRangeAt50m2.Distance, time_new_50m2, 'linear');
            velocity_new_50m2 = interp1(vehiclesInRangeAt50m2.Time, vehiclesInRangeAt50m2.Velocity, time_new_50m2, 'linear');
            acceleration_new_50m2 = interp1(vehiclesInRangeAt50m2.Time, vehiclesInRangeAt50m2.Acceleration, time_new_50m2, 'linear');
            
            % 将新点加入到vehiclesInRangeAt50m2集合中
            vehiclesInRangeAt50m2 = [vehiclesInRangeAt50m2; {id_550m2, time_new_50m2, distance_new_50m2, velocity_new_50m2, acceleration_new_50m2}];
            
            % 同时将新点添加到unchanging_points2
            unchanging_points2 = [unchanging_points2; id_550m2];
        end
    else
        % 绘制为蓝色点
        scatter(time_550m2, distance_550m2, 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'b', 'Marker', '*');
    end
end

% 添加图例和坐标轴标签
legend({'Vehicle 505', 'Vehicle 669', 'Vehicles 505-669 at 1100m'});
xlabel('时间(s)');
ylabel('空间 (m)');
title('Vehicle Trajectories and Points at 1100m');

% 设置图形界限以适应所有数据点
allX = [trajectory505_2(:,2); trajectory669_2(:,2); vehiclesInRangeAt550m2.Time];  
allY = [trajectory505_2(:,3); trajectory669_2(:,3);vehiclesInRangeAt550m2.Distance];  
xlim([min(allX) max(allX)]);  
ylim([min(allY) max(allY)]);  

hold off;
