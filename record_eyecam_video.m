function syncinfo = record_eyecam_video()
syncinfo = [];
imaqreset

eyecam = videoinput('gige', 1, 'Mono8');
src = getselectedsource(eyecam);

eyecam.FramesPerTrigger = Inf;
eyecam.LoggingMode = 'disk';
eyecam.ReturnedColorspace = 'grayscale';
eye_roi = [0 0 eyecam.VideoResolution];
    
src.ReverseX = 'False';
src.BinningHorizontal = 2;
src.BinningVertical = 2;
src.AcquisitionFrameRateRaw = 30000;
src.AcquisitionFrameRateAbs = 30;
preview(eyecam)
pause(1)

%% Synching with PsychStimController
pnet('closeall')
rigSpecific
socksync = pnet('udpsocket',eyecamport); %socket to listen on for input from PsychStimController
disp('waiting for sync from visual stimulation computer');
while 1
    [KeyIsDown, ~, KeyCode] = KbCheck;
    if KeyIsDown
        key = find(KeyCode);
        if key == 27 % ESC on Windows Keyboard.
            stoppreview(eyecam)
            error('Program Exit!')
        end
    end
    pause (0.001)

    if pnet(socksync, 'readpacket', 80, 'noblock') > 0
        fname = pnet(socksync, 'read', 36);
        break
    end
end
GetSecs; % making it as close as possible to packet input
% stoppreview(eyecam);
disp('sync packet received; started');
disp('Goes into loop. Press ESC to abort');
stopudp = pnet('udpsocket', eyecamport);

pname = [eyecamfolder date '\'];
if ~exist(pname)
    mkdir(pname);
end

if strcmp(fname(1), 'E')
    filename = fname;
else
    filename = fname(8:end);
end
disp(['Saving to: ', pname, filename, '.mp4'])
diskLogger = VideoWriter([pname, filename, '.mp4'], 'MPEG-4'); % OR .mj2 'Motion JPEG 2000'
eyecam.DiskLogger = diskLogger;

start(eyecam);
exitflag = 0;
while 1
    [KeyIsDown, ~, KeyCode] = KbCheck;
    if KeyIsDown
        key = find(KeyCode);
        if key == 27 % ESC on Windows Keyboard.
            break;
        end
    end
    
    % 'stop' = 1937010544 = swapbytes(uint32( hex2dec('73')+(256*hex2dec('74'))+(256*256*hex2dec('6F'))+(256*256*256*hex2dec('70')) ))
    if pnet(socksync, 'readpacket', 80, 'noblock') > 0
        if strcmp(fname(1), 'E')
            msg = pnet(socksync, 'read', 1,  'uint32');
            if (msg == 1937010544 | (msg==4 & exitflag==1))
                break
            else
                syncinfo = [syncinfo; msg, eyecam.FramesAcquired];
                exitflag = 1;
            end
        else
            txtmsg = pnet(socksync, 'readline', 'char');
            if strncmp(txtmsg,'stop',4)
                break
            else
                syncinfo = [syncinfo; str2double(txtmsg), eyecam.FramesAcquired];
            end
        end
    end
    
end
save([pname, filename, '.mat'], 'syncinfo')
stoppreview(eyecam);
stop(eyecam);
pnet(socksync,'close');
close all
