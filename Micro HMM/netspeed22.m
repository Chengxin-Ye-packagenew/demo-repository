% 假设数据已经加载到 MATLAB 环境中  
trajectory=trajectory505;  
% % 提取输入（时间）和目标输出（速度和加速度） 
inputs = trajectory.globaltime;  % 假设trajectory是包含所有数据的结构体  
speeds = trajectory.vspeed;   % 速度数据 
accelerations = trajectory.vacc;  % 加速度数据  
    % % 提取输入（时间）和目标输出（速度和加速度） 
% inputs = trajectory(:,2);  % 假设trajectory是包含所有数据的结构体  
% % dis = trajectory.Var5;
% speeds = trajectory(:,4);   % 速度数据 
% % % inputs=[inputs,dis];
% accelerations = trajectory(:,5);  % 加速度数据  

% 数据归一化（可选，但推荐）  
% 这里省略了数据归一化的代码，你可以根据需要添加  
  
% 切分数据集为训练集和验证集  
trainRatio = 0.9; % 90% 训练集  
valRatio = 0.1; % 10% 验证集  
  
% 使用randperm函数来确定训练集和验证集的索引  
idx = randperm(length(inputs));  
trainIdx = idx(1:round(trainRatio*length(idx)));  
valIdx = idx(round(trainRatio*length(idx))+1:end);  
  
% 为速度和加速度分别创建训练集和验证集  
trainInputsSpeed = inputs(trainIdx,:);  
trainTargetsSpeed = speeds(trainIdx);  
valInputsSpeed = inputs(valIdx,:);  
valTargetsSpeed = speeds(valIdx);  
  
trainInputsAcceleration = inputs(trainIdx,:);  
trainTargetsAcceleration = accelerations(trainIdx);  
valInputsAcceleration = inputs(valIdx,:);  
valTargetsAcceleration = accelerations(valIdx);  
  
% 接下来，为速度和加速度分别创建、训练和验证神经网络模型  
  
% 创建神经网络模型，速度和加速度可以使用相同的网络结构  
hiddenLayerSize = 10;  % 隐藏层神经元数量  
netSpeed = fitnet(hiddenLayerSize);  
netAcceleration = fitnet(hiddenLayerSize);  
  
% 设置训练参数（可选，这里以速度网络为例，加速度网络类似）  
netSpeed.trainParam.epochs = 100000;  
netSpeed.trainParam.goal = 1e-5;  
netSpeed.trainParam.lr = 0.01;   
  
% 训练神经网络模型  
netSpeed = train(netSpeed, trainInputsSpeed', trainTargetsSpeed');  
netAcceleration = train(netAcceleration, trainInputsAcceleration', trainTargetsAcceleration');  
  
% 验证神经网络模型  
valOutputsSpeed = netSpeed(valInputsSpeed');  
valOutputsAcceleration = netAcceleration(valInputsAcceleration');  
  
performanceSpeed = perform(netSpeed, valTargetsSpeed', valOutputsSpeed);  
performanceAcceleration = perform(netAcceleration, valTargetsAcceleration', valOutputsAcceleration);  
  
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
