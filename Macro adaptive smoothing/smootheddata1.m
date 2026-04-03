function [result_new]=smootheddata1(unique_x,unique_t,result)
delta=50;
sigma=36;
cfree=70;
ccong=-15;
delta_v=10;
vc=50;

result(isnan(result)) = 0;


distance_free=zeros(size(result,1),size(result,2));
distance_congestion=zeros(size(result,1),size(result,2));
sumspeed_free=zeros(size(result,1),size(result,2));
sumspeed_congestion=zeros(size(result,1),size(result,2));
fafree=zeros(size(result,1),size(result,2));
facongestion=zeros(size(result,1),size(result,2));
for i=1:size(result,1)
    for j=1:size(result,2)
        for p=1:size(result,1)
            for q=1:size(result,2)
                if result(i,j)==0
                    if (i-delta <= p)&& (p <= i+delta) && (j-sigma <= q)&&(q <= j+sigma)&&(result(p,q)~=0)
                        % 计算窗口中的所有点与目标点之间的距离
                        fafree(p,q)=exp(-(abs((unique_x(i)-unique_x(p))/delta)+(abs(unique_t(j)-unique_t(q)-(((unique_x(i)-unique_x(p))/cfree)))/sigma)));
                        sumspeed_free(i,j)=sumspeed_free(i,j)+fafree(p,q)*result(p,q);
                        distance_free(i,j) = distance_free(i,j)+fafree(p,q);
                        facongestion(p,q)=exp(-(abs((unique_x(i)-unique_x(p))/delta)+(abs(unique_t(j)-unique_t(q)-(((unique_x(i)-unique_x(p))/ccong)))/sigma)));
                        sumspeed_congestion(i,j)=sumspeed_congestion(i,j)+facongestion(p,q)*result(p,q);
                        distance_congestion(i,j) = distance_congestion(i,j)+facongestion(p,q);
                    end
                end
            end
        end
        if result(i,j)==0
        V_free(i,j)=sumspeed_free(i,j)/distance_free(i,j);
        V_congestion(i,j)=sumspeed_congestion(i,j)/distance_congestion(i,j);
        V_star=min(V_free(i,j),V_congestion(i,j));
        w(i,j)=(1+tanh((vc-V_star)/delta_v))/2;
        V(i,j)=w(i,j)*V_free(i,j)+(1-w(i,j))*V_congestion(i,j);
        end
        if result(i,j)~=0
            V(i,j)=result(i,j);
        end

    end
end
result_new=V;
