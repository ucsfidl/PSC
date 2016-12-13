
rigSpecific;
sockrunning = pnet('udpsocket',runningport)
    
pause(5)
while 1
    
    rsize=pnet(sockrunning,'readpacket',80,'noblock')
    if rsize > 0
        disp('packet received')
%         f = maxframe+1;
%         runorstill = fix(pnet(sockrunning,'read',1,'int16','native'))
        runorstill = fix(pnet(sockrunning,'read',1,'int16','native'))
        % fprintf(runorstill);
%         iter = mod(runorstill,5)
    end
    
end