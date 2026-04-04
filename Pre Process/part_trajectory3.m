% 绘制两辆特定车的轨迹  
figure;  
hold on;  
% plot(trajectory505(:,2), trajectory505(:,3), 'r-', 'LineWidth', 2);  
% plot(trajectory669(:,2), trajectory669(:,3), 'r-', 'LineWidth', 2);
plot(trajectory505.globaltime, trajectory505.y, 'r-', 'LineWidth', 2);
plot(trajectory669.globaltime, trajectory669.y, 'r-', 'LineWidth', 2);
% 获取车辆编号对应的时间范围
time_min550 = earliest_550_data1.Time(vehiclesToDraw(1));
time_max550 = earliest_550_data1.Time(vehiclesToDraw(2));

% time_min450 = earliest_450_data.Time(vehiclesToDraw(1));
% time_max450 = earliest_450_data.Time(vehiclesToDraw(2));
% 
time_min350 = earliest_350_data1.Time(vehiclesToDraw(1));
time_max350 = earliest_350_data1.Time(vehiclesToDraw(2));

time_min50 = earliest_50_data1.Time(vehiclesToDraw(1));
time_max50 = earliest_50_data1.Time(vehiclesToDraw(2));

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

% 筛选时间范围内的车辆经过 350m 的轨迹点
vehiclesInRangeAt350m1 = earliest_350_data1(earliest_350_data1.Time >= time_min350 & earliest_350_data1.Time <= time_max350, :);
% 获取筛选后的数据的索引
indicesInOriginalData350m1 = find(earliest_350_data1.Time >= time_min350 & earliest_350_data1.Time <= time_max350);
% 对筛选后的数据按照时间排序
vehiclesInRangeAt350m1 = sortrows(vehiclesInRangeAt350m1, "Time");

% % 绘制这些轨迹点


% 绘制这些轨迹点
scatter(vehiclesInRangeAt50m1.Time, vehiclesInRangeAt50m1.Distance, 'MarkerFaceColor', [1 0 1], 'Marker', '*');
% 给定的斜率  
slope = -7.7157;
% slope =-5.531255714089974e-04;
% 定义浅蓝色的 RGBA 值  

lightBlueColor = [0.6 0.8 1.0 0.3]; % RGBA 格式：[红 绿 蓝 透明度]

% 初始化存储斜率和截距的数组  

shockwave_slopes = [];  

shockwave_intercepts = []; 

% 绘制通过 Var10 等于 1100 的每个点的线  
for i = 1:height(vehiclesInRangeAt550m1)  
    % 从轨迹点数据中提取 x 和 y（
    x_trajectory = vehiclesInRangeAt550m1.Time(i);
    y_trajectory = vehiclesInRangeAt550m1.Distance(i);

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
  
% % 设置图形界限以适应所有数据点  
allX = [trajectory505.globaltime; trajectory669.globaltime; vehiclesInRangeAt550m1.Time];  
allY = [trajectory505.y; trajectory669.y;vehiclesInRangeAt550m1.Distance];  
% allX = [trajectory505(:,2); trajectory669(:,2); vehiclesInRangeAt550m1.Time];  
% allY = [trajectory505(:,3); trajectory669(:,3);vehiclesInRangeAt550m1.Distance];  
xlim([min(allX) max(allX)]);  
ylim([min(allY) max(allY)]);  
  
hold off;
%%
% 初始化存储不变点和变化点的矩阵
unchanging_points = [];
changing_points = [];

% 获取两个数据集的 id
ids_50m = vehiclesInRangeAt50m1.TrajectoryID;
ids_550m = vehiclesInRangeAt550m1.TrajectoryID;

% 创建一个新的图形
figure;
hold on;

% 绘制初始的车辆轨迹
plot(trajectory505.globaltime, trajectory505.y, 'r-', 'LineWidth', 2);
plot(trajectory669.globaltime, trajectory669.y, 'r-', 'LineWidth', 2);
% plot(trajectory505(:,2), trajectory505(:,3), 'r-', 'LineWidth', 2);  
% plot(trajectory669(:,2), trajectory669(:,3), 'r-', 'LineWidth', 2);
% 遍历 50m 轨迹数据
for i = 1:height(vehiclesInRangeAt50m1)
    % 获取当前车辆的 id 和时间、距离
    id_50m = vehiclesInRangeAt50m1.TrajectoryID(i);
    time_50m = vehiclesInRangeAt50m1.Time(i);
    distance_50m = vehiclesInRangeAt50m1.Distance(i);
    
    % 检查是否在 550m 数据中存在相同的 id
    idx_550m = find(ids_550m == id_50m);
    
    if ~isempty(idx_550m) % 如果 50m 数据集中的 id 也存在于 550m 数据集
        % 绘制为蓝色点
        scatter(time_50m, distance_50m, 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'b', 'Marker', '*');
        % 保存该 id 为不变点
        unchanging_points = [unchanging_points; id_50m];
    else
        % 绘制为红色点
        scatter(time_50m, distance_50m, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r', 'Marker', '*');
        % 保存该 id 为变化点
        changing_points = [changing_points; id_50m,1];
    end
end

% 遍历 550m 轨迹数据
for i = 1:height(vehiclesInRangeAt550m1)
    % 获取当前车辆的 id 和时间、距离
    id_550m = vehiclesInRangeAt550m1.TrajectoryID(i);
    time_550m = vehiclesInRangeAt550m1.Time(i);
    distance_550m = vehiclesInRangeAt550m1.Distance(i);
    
    % 检查是否在 50m 数据中存在相同的 id
    idx_50m = find(ids_50m == id_550m);
    
    if isempty(idx_50m) % 如果 550m 数据集中的 id 不存在于 50m 数据集
        % 绘制为红色点
        scatter(time_550m, distance_550m, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r', 'Marker', '*');
        % 保存该 id 为变化点
        changing_points = [changing_points; id_550m,2];
    else
         % 绘制为红色点
        scatter(time_550m, distance_550m, 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'b', 'Marker', '*');
    end
end

% 添加图例和坐标轴标签
legend({'Vehicle 505', 'Vehicle 669', 'Vehicles 505-669 at 1100m'});
xlabel('时间(s)');
ylabel('空间 (m)');
title('Vehicle Trajectories and Points at 1100m');

% 设置图形界限以适应所有数据点
% allX = [trajectory505.globaltime; trajectory669.globaltime; vehiclesInRangeAt550m1.Time; vehiclesInRangeAt50m1.Time];
% allY = [trajectory505.y; trajectory669.y; vehiclesInRangeAt550m1.Distance; vehiclesInRangeAt50m1.Distance];
% allX = [trajectory505(:,2); trajectory669(:,2); vehiclesInRangeAt550m1.Time];  
% allY = [trajectory505(:,3); trajectory669(:,3);vehiclesInRangeAt550m1.Distance];  
xlim([min(allX) max(allX)]);
ylim([min(allY) max(allY)]);

hold off;
%%
% 初始化存储时间差的矩阵
T = [];

% 遍历 50m 轨迹数据
for i = 1:height(vehiclesInRangeAt50m1)
    % 获取当前车辆的 id 和时间
    id_50m = vehiclesInRangeAt50m1.TrajectoryID(i);
    time_50m = vehiclesInRangeAt50m1.Time(i);
    
    % 检查是否在 550m 数据中存在相同的 id
    idx_550m = find(ids_550m == id_50m);
    
    if ~isempty(idx_550m) % 如果 50m 数据集中的 id 也存在于 550m 数据集
        % 获取 550m 数据中的时间
        time_550m = vehiclesInRangeAt550m1.Time(idx_550m);
        
        % 计算时间差
        time_diff = abs(time_550m - time_50m);
        
        % 将车辆 id 和对应的时间差存储到矩阵 T 中
        T = [T; id_50m, time_diff];
    end
end

% 打印结果
disp(T);
