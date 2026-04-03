% datat=data_whole1_new.Var10;
% datax=data_whole1_new.Var5;
% datav=data_whole1_new.Var8;
datat=data_new_1lane.time;
datax=data_new_1lane.x;
datav=data_new_1lane.tan_acc;
% datat=data_NGSIM2.globaltime;
% datax=data_NGSIM2.y;
% datav=data_NGSIM2.vspeed;
datat = round(datat, 0);
datax = round(datax, 0);
% trafficpoints_transformed = round(trafficpoints_transformed, 0);
unique_x1_1006 = unique(datax);
unique_t1_1006 = unique(datat);

result12_1006 = zeros(length(unique_x1_1006), length(unique_t1_1006)); % 创建结果矩阵

i = 1;
while i <= length(unique_x1_1006)
        indices = (datax == unique_x1_1006(i));
        current_indices_positions = find(indices);%找到重合位置
        current_t=[];
        location=[];
        current_v=[];
        ab=1;
        while ab <= size(current_indices_positions,1)
            current_t(ab)=datat(current_indices_positions(ab));%记录当前位置的时间
            location(ab)=find(unique_t1_1006 == datat(current_indices_positions(ab)));%这是记录unique里面的时间位置
            current_v(ab)=datav(current_indices_positions(ab));%记录当前点速度
            %这个记录的是unique_t里面的位置，并且这个位置上的速度值，方便定位j，并且记录时间值和时间的位置值
            ab=ab+1;
        end
        cd=1;
        while cd <=size(current_indices_positions,1)%这是相同位置的点的个数
                loc_v=find(location == location(cd));%找到location中unique里面相同时间的元素位置，这是unique的时间位置
                sum_v=0;
                s=1;
                for s=1:size(loc_v,2)
                    sum_v=sum_v+current_v(loc_v(s));
                    s=s+1;
                end
                avg_velocity = sum_v/size(loc_v,2);
                result12_1006(i,location(cd))=avg_velocity;
                cd=cd+1;
        end
        

        
    
    i = i + 1;
end
