function mouseListener_rt()
% mouseListener_rt saves the optical mouse data stream, computes running 
% speed on the fly and sends RUNNING or STILL to PsychStimController, and
% then 
rigSpecific;
pnet('closeall')  %% why do this--commented out MPS 07/10/2016
% sockm (port 8936) for listening to MouseSender and getting data()
% socsync (port 8939) for listening to PsychStimController for outputfilename and 'close'
% sockrunning (port 8940) used only for sending RUN or STILL to PsychStimController

% define sockets
sockrunning = pnet('udpsocket',8940); %socket to send output to fPsychStimController
socksync = pnet('udpsocket',8939); %socket to listen on for input from PsychStimController
sockm = pnet('udpsocket',8936);  %socket to listen on for input from mouse sender
% pnet(socksync,'setreadtimeout',10);
% pnet(sockm,'setreadtimeout',10);

%% setup for real time analysis, socket to send RUNNING = int16(1) or STILL = int16(0) 
% to psychstim computer.   MPS 07/10/2016
maxhrs =2;
ti0 = 0;
speed = 0;
lastspeed = speed;
runspeed = 2;  %cm/sec
RUNNING = int16(1);
STILL = int16(0);
runorstill = int16(0);
dxi = 0;
dyi = 0;
t_int = 0.1;  % 100 msec integration time
runtime = 0.;
stilltime = 0.;
%%

dX=zeros(1,60*60*60*maxhrs,'int16');
dY=dX;
dChannel  = dX;
dRunning = dX;
dT = zeros(1,length(dX));


samp = 0;
samp0 = 1;
saveInterval = 10;
printInterval = 30;
nPrints=0;
nSaves=0;

    % Create a figure and axes
    runstillfig = figure('Visible','on', ...
        'Name','Run Monitor', ...
        'MenuBar', 'none','ToolBar','auto', ...
        'Position',[20,500,500,200]);
    
   % Create slider
    sldrun = uicontrol('Style', 'slider',...
        'Min',0,'Max',120,'Value',1,...
        'Position', [20 20 400 20]) ;
					
    % Add a text uicontrol to label the slider.
    txtrun = uicontrol('Style','text',...
        'Position',[20 45 120 20],...
        'String','running time');

   % Create slider
    sldstill = uicontrol('Style', 'slider',...
        'Min',0,'Max',120,'Value',1,...
        'Position', [20 80 400 20]) ;
					
    % Add a text uicontrol to label the slider.
    txtstill = uicontrol('Style','text',...
        'Position',[20 105 120 20],...
        'String','still time');
        
   % Create button    
    tb = uicontrol(runstillfig,'Style','togglebutton',...
                'String','Running/Still',...
                'Value',0,'Position',[20 140 100 30]);
   
% 	runstillfig.Visible = 'on';

figure(runstillfig); drawnow;

disp('waiting for sync from visual stimulation computer');
rsize = pnet(socksync,'readpacket',80)  %block on this call
ti0 = GetSecs; % making it as close as possible to packet input
disp('sync packet received; started');
outputfilename=pnet(socksync,'read' ,36 );
fname = outputfilename(1:11);
disp('Goes into loop. Press ESC to abort');
while 1

    [pressed prtime keycodes] = KbCheck;
    if keycodes(27) == 1 % ESC on Windows Keyboard.
        break;
    end
    
    dsize = pnet(sockm,'readpacket');  %blocks on optical mouse readings, every 2-10 msec
    data = uint16(pnet(sockm,'read',4,'uint16','native'));
    if dsize ~= 8
        continue
    end
    % native = No swapping byte order - use computer's native order
    % uint16 = datatype coming in
    % 4 = size of data
    % data(1) is mouse wheeel, insignificant, 256
    % data(2) low byte has mouse number, 0 or 256
    % data(3) high byte has SIGNED byte of x incrmeent dX
    % data(4) low byte has SIGNED y increment dY
%     disp([data samp]);
    ddm = data(2);
	samp = samp+1;
    dChannel(samp) = cast(ddm, 'int16');
    dT(samp)= GetSecs-ti0;
    ddx =  swapbytes(data(3));
    ddy =  (data(4));
    
    %% new real time segment MPS 07/10/2016
    rm=cast(ddm,'int16');
    rx=cast(ddx,'int16');
    ry=cast(ddy,'int16');
    if rx > 127  % signed values for x and y
        rx = -1*(256-rx);
    end
    if ry > 127
        ry = -1*(256-ry);
    end
    dX(samp) = rx;
    dY(samp) = ry;
    
    %integration time t_int
    % quick and dirty just add the channel 0 and channel 1 y data to get speed, 
    % since it is really only the Y what we use for forward progress, 
    %  and is mostly channel 0.
    
    if dT(samp) <= (dT(samp0) + t_int)
        dxi = dxi + abs(rx);
        dyi = dyi + abs(ry);
    else
        speed = ((double(dxi)+double(dyi))/scalefactor)/t_int;
        dxi = 0;
        dyi = 0;
        samp0 = samp;
%         disp(speed);
        if speed > runspeed
            runtime = runtime + t_int;
        else
            stilltime = stilltime + t_int;
        end
    end
    if speed ~= lastspeed
        if speed > runspeed
            pnet(sockrunning,'write',RUNNING);
            tb.ForegroundColor = 'green';
            tb.String = 'Running';
            runorstill = RUNNING;
            sldrun.Value = runtime;
            txtrun.String = ['Running time: ' num2str(runtime)];

        else
            pnet(sockrunning,'write',STILL);
            tb.ForegroundColor = 'red';
            tb.String = 'Still';
            runorstill = STILL;
            sldstill.Value = stilltime;
            txtstill.String = ['Still time: ' num2str(stilltime)];
        end
        pnet(sockrunning,'writepacket', runninghost, runningport);
        lastspeed = speed;
        drawnow;
        % Add graphical indicator of runorstill, and add indicators of total
        % time running and total time still
        % Update them when runorstill changes
        % use programmable app builder interface (not GUIDE).
    end
    dRunning(samp) = runorstill;
 %% end of realtime segment           
    
% I rationalized the variables
    rsize=pnet(socksync,'readpacket',80,'noblock');
    isclosed = pnet(socksync,'readline' ,20 );
    if strcmp(isclosed,'close')
        break
    end
% 	disp([samp rm rx ry dT(samp) runorstill]);
end
pnet(socksync,'close');
pnet(sockrunning,'close');

%%
% End of running part of the program.
% Now store the data and summarize it.
dT = dT(1:samp);
dChannel = dChannel(1:samp);
dRunning = dRunning(1:samp);
dX = dX(1:samp);
dY = dY(1:samp);

pname = 'C:\data\Trackball\';
if exist('C:\data\Trackball\','dir') ~= 7
	mkdir(pname);
end
save(fullfile(pname,fname),'dX','dY','dT','dChannel', 'dRunning');
disp(['Saved optical mouse data in '  fullfile(pname,fname)]);

mouseTrajectory(fullfile(pname,fname));