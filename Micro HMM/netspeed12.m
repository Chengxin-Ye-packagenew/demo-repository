% 假设数据已经加载到 MATLAB 环境中  
trajectory2=trajectory669;  
% 提取输入（时间）和目标输出（速度和加速度） 
inputs2 = trajectory2.globaltime;  % 假设trajectory是包含所有数据的结构体  
speeds2 = trajectory2.vspeed;   % 速度数据 
accelerations2 = trajectory2.vacc;  % 加速度数据  


% inputs2 = trajectory2(:,2);  % 假设trajectory是包含所有数据的结构体  
% % dis = trajectory.Var5;
% speeds2 = trajectory2(:,4);   % 速度数据 
% % % inputs=[inputs,dis];
% accelerations2 = trajectory2(:,5);  % 加速度数据  
% 数据归一化（可选，但推荐）  
% 这里省略了数据归一化的代码，你可以根据需要添加  
  
% 切分数据集为训练集和验证集  
trainRatio = 0.9; % 90% 训练集  
valRatio = 0.1; % 10% 验证集  
  
% 使用randperm函数来确定训练集和验证集的索引  
idx = randperm(length(inputs2));  
trainIdx = idx(1:round(trainRatio*length(idx)));  
valIdx = idx(round(trainRatio*length(idx))+1:end);  
  
% 为速度和加速度分别创建训练集和验证集  
trainInputsSpeed = inputs2(trainIdx,:);  
trainTargetsSpeed = speeds2(trainIdx);  
valInputsSpeed = inputs2(valIdx,:);  
valTargetsSpeed = speeds2(valIdx);  
  
trainInputsAcceleration = inputs2(trainIdx,:);  
trainTargetsAcceleration = accelerations2(trainIdx);  
valInputsAcceleration = inputs2(valIdx,:);  
valTargetsAcceleration = accelerations2(valIdx);  
  
% 接下来，为速度和加速度分别创建、训练和验证神经网络模型  
  
% 创建神经网络模型，速度和加速度可以使用相同的网络结构  
hiddenLayerSize = 10;  % 隐藏层神经元数量  
netSpeed2 = fitnet(hiddenLayerSize);  
netAcceleration2 = fitnet(hiddenLayerSize);  
  
% 设置训练参数（可选，这里以速度网络为例，加速度网络类似）  
netSpeed2.trainParam.epochs = 100000;  
netSpeed2.trainParam.goal = 1e-5;  
netSpeed2.trainParam.lr = 0.01;   
  
% 训练神经网络模型  
netSpeed2 = train(netSpeed2, trainInputsSpeed', trainTargetsSpeed');  
netAcceleration2 = train(netAcceleration2, trainInputsAcceleration', trainTargetsAcceleration');  
  
% 验证神经网络模型  
valOutputsSpeed = netSpeed2(valInputsSpeed');  
valOutputsAcceleration = netAcceleration2(valInputsAcceleration');  
  
performanceSpeed = perform(netSpeed2, valTargetsSpeed', valOutputsSpeed);  
performanceAcceleration = perform(netAcceleration2, valTargetsAcceleration', valOutputsAcceleration);  
  
  
% 可视化验证结果（可选，以速度为例）  
figure;  
subplot(2,1,1); % 分割画布，用于同时显示速度和加速度的验证结果  
plot(valInputsSpeed, valTargetsSpeed, 'bo'); % 真实的验证集速度数据  
hold on;  
plot(valInputsSpeed, valOutputsSpeed, 'r*'); % 神经网络的预测速度输出  
hold off;  
xlabel('Time (Input)');  
ylabel('Speed (Output)');  
title('Validation Results for Speed');  
legend('Actual','Predicted');  
  
subplot(2,1,2); % 分割画布的下半部分用于显示加速度的验证结果  
plot(valInputsAcceleration, valTargetsAcceleration, 'bo'); % 真实的验证集加速度数据  
hold on;  
plot(valInputsAcceleration, valOutputsAcceleration, 'r*'); % 神经网络的预测加速度输出  
hold off;  
xlabel('Time (Input)');  
ylabel('Acceleration (Output)');  
title('Validation Results for Acceleration');  
legend('Actual','Predicted');

%%
% 可视化验证结果（预测值和真实值分开显示）
figure;

% 速度部分
subplot(2,1,1); % 第一行左：真实速度
scatter(valInputsSpeed, valTargetsSpeed, 50, [0.5 0.5 0.5]); % 灰色点，点大小20
xlabel('Time');
ylabel('Speed');
% grid on;

% 添加图例
legend('real\_world\_data');

figure;
subplot(2,1,1); % 第一行右：预测速度
scatter(valInputsSpeed, valOutputsSpeed,50);
xlabel('Time');
ylabel('Speed');
% 添加图例
legend('HMM model');
% 可视化验证结果（预测值和真实值分开显示）
figure;

% 速度部分
subplot(2,1,1); % 第一行左：真实速度
scatter(valInputsAcceleration, valTargetsAcceleration,50, [0.5 0.5 0.5]);
xlabel('Time');
ylabel('Acceleration');
% 添加图例
legend('HMM model');
grid on;
figure;
subplot(2,1,1); % 第二行右：预测加速度
scatter(valInputsAcceleration, valOutputsAcceleration);
xlabel('Time');
ylabel('Acceleration');
% 添加图例
legend('HMM model');
grid on;

% 添加总标题
sgtitle('Validation Results: Actual vs Predicted (Separated)');
%%
% 读取数据并修改列名
filePath = 'D:\\u盘备用\\排放数据库.xlsx';  % 请根据文件实际路径修改
data = readtable(filePath, 'Sheet', 'Sheet1');

% 修改列名
data.Properties.VariableNames = {'VehicleType', 'EmissionType', 'Speed', 'Acceleration', 'EmissionFactor'};

% 筛选出车辆类型为"小轿车"且排放类型为'NOx'的数据
sedanNOxData = data(strcmp(data.VehicleType, '小轿车') & strcmp(data.EmissionType, 'NOx'), :);
% 定义匹配和计算排放因子的函数
function adjusted_emission_factor = calculateEmissionFactor(row, database)
    % 提取目标速度和加速度
    target_speed = round(row.Speed);         % 车速四舍五入
    target_acceleration = round(row.Acceleration, 1); % 加速度四舍五入
    disp(['正在处理数据点：车辆ID = ', num2str(row.VehicleID), ...
          ', 目标速度 = ', num2str(target_speed), ...
          ', 目标加速度 = ', num2str(target_acceleration), ...
          ', 车辆类型 = ', '小轿车']);

    % 过滤数据库以匹配车辆类型和气体类型
    filtered_db = database(strcmp(database.VehicleType, '小轿车') & ...
                           strcmp(database.EmissionType, 'NOx'), :);
    disp(['匹配数据库后记录数：', num2str(height(filtered_db))]);

    % 检查是否有匹配的数据库记录
    if isempty(filtered_db)
        disp('没有找到匹配的数据库记录。');
        adjusted_emission_factor = NaN;
        return;
    end

    % 将加速度列从 cell 转换为数值型
    filtered_db.Acceleration = str2double(filtered_db.Acceleration);
    
    % 计算车速和加速度差异
    filtered_db.SpeedDiff = abs(filtered_db.Speed - target_speed);
    filtered_db.AccelerationDiff = abs(filtered_db.Acceleration - target_acceleration);
    filtered_db.TotalDiff = filtered_db.SpeedDiff + filtered_db.AccelerationDiff;

    % 找到最接近的匹配记录
    [~, idx] = min(filtered_db.TotalDiff);  % 查找总差异最小的记录
    closest_match = filtered_db(idx, :);
    disp(['找到最接近的匹配记录：车速 = ', num2str(closest_match.Speed), ...
          ', 加速度 = ', num2str(closest_match.Acceleration), ...
          ', 排放因子 = ', num2str(closest_match.EmissionFactor)]);

    % 返回调整后的排放因子
    adjusted_emission_factor = closest_match.EmissionFactor;
    disp(['调整后的排放因子：', num2str(adjusted_emission_factor)]);
end

% 匹配真实数据的排放因子
realEmissionFactors = NaN(length(valTargetsSpeed), 1);  % 初始化一个空数组来存储排放因子
for i = 1:length(valTargetsSpeed)
    % 创建一个结构体 'row' 存储每个数据点的信息
    row = struct('VehicleID', i, 'VehicleType', 'Sedan', 'Speed', valTargetsSpeed(i), 'Acceleration', valTargetsAcceleration(i));
    
    % 调用 calculateEmissionFactor 函数获取排放因子
    realEmissionFactors(i) = calculateEmissionFactor(row, sedanNOxData);
end

% 匹配预测数据的排放因子
predictedEmissionFactors = NaN(length(valOutputsSpeed), 1);  % 初始化一个空数组来存储预测排放因子
for i = 1:length(valOutputsSpeed)
    % 创建一个结构体 'row' 存储每个数据点的信息
    row = struct('VehicleID', i, 'VehicleType', 'Sedan', 'Speed', valOutputsSpeed(i), 'Acceleration', valOutputsAcceleration(i));
    
    % 调用 calculateEmissionFactor 函数获取排放因子
    predictedEmissionFactors(i) = calculateEmissionFactor(row, sedanNOxData);
end

% 可视化：排放因子随时间变化的对比
figure;
% 假设 valInputsSpeed 是时间数据，这里我们用它作为横坐标
time = valInputsSpeed;  % 如果 valInputsSpeed 是时间数据，直接使用它

% 绘制真实数据排放因子
scatter(time, realEmissionFactors, 'bo', 'DisplayName', '真实数据排放因子');
hold on;

% 绘制预测数据排放因子
scatter(time, predictedEmissionFactors, 'r*',  'DisplayName', '预测数据排放因子');

% 图表设置
xlabel('时间 (Time)', 'FontSize', 12);
ylabel('排放因子 (Emission Factor)', 'FontSize', 12);
title('NOx 排放因子随时间变化的对比', 'FontSize', 14);
legend('show');
grid on;

% 美化图形
set(gca, 'FontSize', 12);  % 设置坐标轴字体大小
hold off;
%%
% 可视化：排放因子随时间变化的对比（分开显示）
figure;

% 子图1：真实数据排放因子
subplot(2,2,1);
scatter(valInputsAcceleration, valTargetsAcceleration, 'bo', 'DisplayName', '真实数据排放因子');
xlabel('时间 (Time)', 'FontSize', 12);
ylabel('排放因子 (Emission Factor)', 'FontSize', 12);
title('真实数据 NOx 排放因子随时间变化', 'FontSize', 14);
legend('show');
grid on;

% 子图2：预测数据排放因子
subplot(2,2,2);
scatter(valInputsAcceleration, valOutputsAcceleration', 'r*', 'DisplayName', '预测数据排放因子');
xlabel('时间 (Time)', 'FontSize', 12);
ylabel('排放因子 (Emission Factor)', 'FontSize', 12);
title('预测数据 NOx 排放因子随时间变化', 'FontSize', 14);
legend('show');
grid on;
% 设置Y轴范围 - 方法1：在创建图形后立即设置
ax1 = gca; % 获取当前坐标轴
% ax1.YLim = [0, 7e-3]; % 使用科学计数法
% 美化图形
set(gca, 'FontSize', 12);  % 设置坐标轴字体大小
%%
% 可视化验证结果（可选，以速度为例）  
figure;  
subplot(3,1,1); % 分割画布，用于同时显示速度和加速度的验证结果  
plot(valInputsSpeed, valTargetsSpeed, 'bo'); % 真实的验证集速度数据  
hold on;  
plot(valInputsSpeed, valOutputsSpeed, 'r*'); % 神经网络的预测速度输出  
hold off;  
xlabel('Time (Input)');  
ylabel('Speed (Output)');  
title('Validation Results for Speed');  
legend('Actual','Predicted');  
  
subplot(3,1,2); % 分割画布的下半部分用于显示加速度的验证结果  
plot(valInputsAcceleration, valTargetsAcceleration, 'bo'); % 真实的验证集加速度数据  
hold on;  
plot(valInputsAcceleration, valOutputsAcceleration, 'r*'); % 神经网络的预测加速度输出  
hold off;  
xlabel('Time (Input)');  
ylabel('Acceleration (Output)');  
title('Validation Results for Acceleration');  
legend('Actual','Predicted');

subplot(3,1,3); % 分割画布的下半部分用于显示加速度的验证结果  
% 绘制真实数据排放因子
scatter(time, realEmissionFactors, 'bo', 'DisplayName', 'Actual');
hold on;

% 绘制预测数据排放因子
scatter(time, predictedEmissionFactors, 'r*',  'DisplayName', 'Predicted');

% 图表设置
xlabel('Time');
ylabel('Emission Factor' );
title('Validation Results for Emission Factor');
legend('Actual','Predicted');


