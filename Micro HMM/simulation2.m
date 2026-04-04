
% % 假设你的数据已经加载到 MATLAB 环境中  
% % 提取输入和目标输出  
inputs505 = trajectory505.globaltime;  
targets505 = trajectory505.y;  

inputs669 = trajectory669.globaltime';  
targets669 = trajectory669.y';  
% inputs505 = trajectory505(:,2);  
% targets505 = trajectory505(:,3);  
% 
% inputs669 = trajectory669(:,2)';  
% targets669 = trajectory669(:,3)';  
% targets505_2 = trajectory505_2.y;  
% 数据归一化（可选，但推荐）  
% 这里省略了数据归一化的代码，你可以根据需要添加  

% 切分数据集为训练集和验证集  
trainRatio = 0.9; % 90% 训练集  
valRatio = 0.1; % 10% 验证集  

% 使用randperm和round函数来确定训练集和验证集的索引  
idx505 = randperm(length(inputs505));  
trainIdx505 = idx505(1:round(trainRatio*length(idx505)));  
valIdx505 = idx505(round(trainRatio*length(idx505))+1:end);  

trainInputs505 = inputs505(trainIdx505);  
trainTargets505 = targets505(trainIdx505);  
valInputs505 = inputs505(valIdx505);  
valTargets505 = targets505(valIdx505);  

% 对trajectory669做同样的处理  
idx669 = randperm(length(inputs669));  
trainIdx669 = idx669(1:round(trainRatio*length(idx669)));  
valIdx669 = idx669(round(trainRatio*length(idx669))+1:end);  

trainInputs669 = inputs669(trainIdx669);  
trainTargets669 = targets669(trainIdx669);  
valInputs669 = inputs669(valIdx669);  
valTargets669 = targets669(valIdx669);  

% 接下来，你可以使用这些训练集和验证集来训练和验证你的神经网络模型。


% 接下来，创建、训练和验证神经网络模型  

% 创建神经网络，假设我们使用一个具有10个神经元的隐藏层  
hiddenLayerSize = 10;  
net = fitnet(hiddenLayerSize);  

% 设置训练参数（可选）  
net.trainParam.epochs = 100000;  % 训练的最大迭代次数  
net.trainParam.goal = 1e-1;    % 训练的目标误差  
net.trainParam.lr = 0.05;      % 学习率  

% 训练神经网络  
net = train(net, trainInputs505', trainTargets505');  

% 验证神经网络  
valOutputs505 = net(valInputs505');  
performance = perform(net, valTargets505', valOutputs505); % 计算验证集上的性能  
fprintf('Validation Performance for trajectory505: %f\n', performance);  

% % % 可视化验证结果（可选）  
% figure;  
% plot(valInputs505, valTargets505, 'bo'); % 真实的验证集数据  
% hold on;  
% plot(valInputs505, valOutputs505, 'r*'); % 神经网络的预测输出  
% hold off;  
% xlabel('Var10 (Input)');  
% ylabel('Var5 (Output)');  
% title('Validation Results for trajectory505');  
% legend('Actual','Predicted');  

% 对trajectory669进行相同的神经网络创建、训练和验证操作  
%% ...（类似于上面的代码，但是使用trajectory669的训练和验证数据集）
% 创建神经网络，假设我们使用一个具有10个神经元的隐藏层  
hiddenLayerSize = 10;  
net1 = fitnet(hiddenLayerSize);  

% 设置训练参数（可选）  
net1.trainParam.epochs = 100000;  % 训练的最大迭代次数  
net1.trainParam.goal = 1e-5;    % 训练的目标误差  
net1.trainParam.lr = 0.05;      % 学习率  

% 训练神经网络  
net1 = train(net1, trainInputs669, trainTargets669);  

% 验证神经网络  
valOutputs669 = net1(valInputs669);  
performance = perform(net1, valTargets669, valOutputs669); % 计算验证集上的性能  
fprintf('Validation Performance for trajectory505: %f\n', performance);  
% % 
% % 可视化验证结果（可选）  
% figure;  
% plot(valInputs669, valTargets669, 'bo'); % 真实的验证集数据  
% hold on;  
% plot(valInputs669, valOutputs669, 'r*'); % 神经网络的预测输出  
% hold off;  
% xlabel('Var10 (Input)');  
% ylabel('Var5 (Output)');  
% title('Validation Results for trajectory669');  
% legend('Actual','Predicted');  

