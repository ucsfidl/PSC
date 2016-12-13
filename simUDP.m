function simudpkey = SimUDP()
	[ keyIsDown, seconds, keyCode ] = KbCheck;
    if keyIsDown
        key = find(keyCode);
        switch key
            %simudpkey 3 corresponds to grey screen
            case 49
                simudpkey = 1;
            case 50
                simudpkey = 2;
            case 51
                simudpkey = 3;
            case 52
                simudpkey = 4;
            case 53
                simudpkey = 5;
            case 54
                simudpkey = 6;
            case 55
                simudpkey = 7;
            case 56
                simudpkey = 8;
            case 57
                simudpkey = 9;

            case 27
                simudpkey = 27;
            otherwise
                simudpkey = 0;
        end
    else
        simudpkey = 0;
    end
end
    
% key 49 which is 1
% key 50 which is 2
% key 27 which is ESCAPE


