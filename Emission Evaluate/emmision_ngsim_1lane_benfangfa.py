import pandas as pd
import numpy as np

# 单一CSV文件路径
csv_file = 'D:\\image_vsp\\data_ngsim_1lane_1direction_0.05_benfangfa.csv'
print(f"读取 CSV 文件: {csv_file}")

# 根据实际文件格式，重新定义列名
new_column_names = ['车辆ID', '时间', 'X_UTM51N', '速度', '加速度']

# 加载排放数据库
database_path = 'D:\\u盘备用\\排放数据库.xlsx'
database = pd.read_excel(database_path, skiprows=[0, 1], names=['车辆类型', '气体类型', '速度', '加速度', '排放因子'])
print("排放数据库已加载，前几行：")
print(database.head())

# 数据库列类型转换
database['速度'] = pd.to_numeric(database['速度'], errors='coerce')
database['加速度'] = pd.to_numeric(database['加速度'], errors='coerce')

# 读取 CSV 文件并指定列名
# 读取 CSV 文件，跳过第一行，并指定新的列名
data_points = pd.read_csv(csv_file, skiprows=1, names=new_column_names)

# 过滤掉加速度为 NaN 的行
filtered_df = data_points.dropna(subset=['加速度'])

# 将过滤后的数据重新赋值给 data_points
data_points = filtered_df
print("数据点已加载，前几行：")
print(data_points.head())

# 如果未找到车辆类型列，添加一列默认值为 '小轿车'
if '车辆类型' not in data_points.columns:
    data_points['车辆类型'] = '小轿车'
    print("未找到车辆类型列，已默认设置为 '小轿车'。")

# 定义匹配和计算排放因子的函数
def calculate_emission_factor(row, database):
    # 提取目标速度和加速度
    target_speed = round(row['速度'])
    target_acceleration = round(row['加速度'], 1)
    print(f"\n正在处理数据点：车辆ID = {row['车辆ID']}, 目标速度 = {target_speed}, 目标加速度 = {target_acceleration}, 车辆类型 = {row['车辆类型']}")

    # 过滤数据库以匹配车辆类型和气体类型
    filtered_db = database[(database['车辆类型'] == row['车辆类型']) & (database['气体类型'] == 'NOx')]
    print(f"匹配数据库后记录数：{len(filtered_db)}")

    # 检查是否有匹配的数据库记录
    if filtered_db.empty:
        print("没有找到匹配的数据库记录。")
        return None

    # 计算车速和加速度差异
    filtered_db['速度差'] = (filtered_db['速度'] - target_speed).abs()
    filtered_db['加速度差'] = (filtered_db['加速度'] - target_acceleration).abs()
    filtered_db['总差'] = filtered_db['速度差'] + filtered_db['加速度差']

    # 找到最接近的匹配记录
    closest_match = filtered_db.loc[filtered_db['总差'].idxmin()]
    print(f"找到最接近的匹配记录：车速 = {closest_match['速度']}, 加速度 = {closest_match['加速度']}, 排放因子 = {closest_match['排放因子']}")

    # 返回调整后的排放因子
    adjusted_emission_factor = closest_match['排放因子']
    print(f"调整后的排放因子：{adjusted_emission_factor}")
    return adjusted_emission_factor

# 计算排放因子
print("\n开始计算排放因子...")
data_points['排放因子'] = data_points.apply(lambda row: calculate_emission_factor(row, database), axis=1)
print("排放因子已计算完成，前几行：")
print(data_points[['车辆ID', '排放因子']].head())

def calculate_emission_between_points(row1, row2):
    # 计算两点之间的距离（单位: 米）
    distance = abs(row2['X_UTM51N'] - row1['X_UTM51N'])
    
    # 计算两点之间的时间差（单位: 秒）
    time_diff = row2['时间'] - row1['时间']
    
    # 计算平均排放因子
    avg_emission_factor = (row1['排放因子'] + row2['排放因子']) / 2 if not pd.isna(row1['排放因子']) and not pd.isna(row2['排放因子']) else None
    
    # 计算排放量 (单位：克)
    if avg_emission_factor is not None and time_diff > 0:
        emission =  avg_emission_factor * time_diff
    else:
        emission = None
    
    print(f"\n两点间距离：{distance:.2f} 米，时间差：{time_diff:.2f} 秒，平均排放因子：{avg_emission_factor}, 排放量：{emission}")
    return emission, distance, row1['时间'], row2['时间']

# 记录每辆车的排放数据
emission_data = []
print("\n开始计算相邻点的排放量...")

# 按车辆ID分组，计算相邻点之间的排放量
for vehicle_id, group in data_points.groupby('车辆ID'):
    print(f"\n处理车辆ID: {vehicle_id}，轨迹点数量: {len(group)}")
    group = group.sort_values(by='时间')  # 按时间排序
    for i in range(1, len(group)):
        row1 = group.iloc[i-1]
        row2 = group.iloc[i]
        
        emission, distance, start_time, end_time = calculate_emission_between_points(row1, row2)
        
        emission_data.append({
            '车辆ID': vehicle_id,
            '起始时间': start_time,
            '结束时间': end_time,
            '起始位置': row1['X_UTM51N'],
            '结束位置': row2['X_UTM51N'],
            '起始点排放因子': row1['排放因子'],
            '结束点排放因子': row2['排放因子'],
            '距离区间': distance,
            '排放量': emission
        })

# 转换为 DataFrame
emission_df = pd.DataFrame(emission_data)

# 定义导出路径
output_csv_file = 'D:\\image_vsp\\data_ngsim_1lane_1direction_0.05_benfangfa_nox.csv'

# 导出为 CSV 文件
emission_df.to_csv(output_csv_file, index=False, encoding='utf-8-sig')
print("\n已将排放数据导出到:")
print(output_csv_file)
