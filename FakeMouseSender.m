load ('T_UCSC355A_151211_190034.mat');
disp('ESC to end');
% [FileName,PathName] = uigetfile('*.mat','Select the MATLAB Trackball file');
% load([PathName FileName]);
%
rigSpecific;
FakePsychStim = 0;  %set to zero if mimicking only mouseSender
%
% sockm (port 8936) for pretinding to be MouseSender and sending to
% mouseListener
%
% socsync (port 8939) for outputfilename and 'close'; normally done by
% PsychStimController
%
% sockrunning (port 8940) used only for sending RUN or STILL to PsychStimController
socksync = pnet('udpsocket',8941);

sockm = pnet('udpsocket',8401);
pnet(sockm,'udpconnect','localhost',mlistenport);
c = clock;
fname = sprintf('%d%02d%02d_%02d%02d%02d', ...
    c(1)-2000, c(2), c(3), c(4), c(5), fix(c(6)));
if FakePsychStim
    pnet(socksync,'write',fname);
    pnet(socksync,'writepacket', trackballhost, trackballport);
end
k = 1;
done = 0;
tdisp = 10;
t0 =  GetSecs() + dT(1);
while ~done
    waiting = 1;
    while waiting > 0
        t = GetSecs() - t0;
        if t > tdisp
            disp(sprintf('t=%8.3f k=%d dT(k)=%8.3f minutes=%6.3f\n',t,k,dT(k),dT(k)/60));
            tdisp = tdisp + 10;   % display every 10 sec
        end
        [ keyIsDown, seconds, keyCode ] = KbCheck;
        if keyIsDown
            if keyCode(27) 
                done = 1;
                waiting = 0;
            end
        end
        if t > dT(k)
            waiting = 0;
        end
    end
    data = [1,dChannel(k),dX(k),dY(k)];
    pnet(sockm, 'write', data, 'native');
    pnet(sockm,'writepacket');
    
    k = k+1;
end
if FakePsychStim
    pnet(socksync,'write','close');
    pnet(socksync, 'writepacket', trackballhost, trackballport);
end
disp('FakeMouseSender Finished');








