function  [ind1,ind2] = EucOutRemove(x1,x2, threshold)
        
if size(x1,1)>size(x1,2)
    x1 = x1';
    x2 = x2';
end

        y1 = x1;
        y2 = x2;
        
        EucDist1 = zeros(1,size(x1,1));
        EucDist2 = zeros(1,size(x2,1));
        for i = 1:size(x1,1)
            EucDist1(i) = sqrt(mean((x1(1,:)-x1(i,:)).^2));    
            EucDist2(i) = sqrt(mean((x2(1,:)-x2(i,:)).^2));    
        end
        
        ind1 = find(EucDist1<(1-threshold)*mean(EucDist1) | EucDist1>(1+threshold)*mean(EucDist1));
        ind2 = find(EucDist2<(1-threshold)*mean(EucDist2) | EucDist2>(1+threshold)*mean(EucDist2));
         
       % y1(ind1,:) = [];

        
        
end
