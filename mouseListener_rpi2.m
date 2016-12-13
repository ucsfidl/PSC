function mouseListener_rpi2(varargin)
% mouseListener_rpi saves the optical mouse data stream, computes running
% speed on the fly every 100msec, and
% sends RUNNING+1 (=2) or STILL+1 (=1) to PsychStimController.mod(3,
% If runthresh argument is omitted, it defaults to 1.5 cm/sec
% optional arguments (run_conditions [], still_conditions [], runthresh)
% run_conditions defaults to [1 3 5]; still_conds defaults to [2 3 5], and runthresh defaults to 2 cm/sec
nVarargs = length(varargin);
run_conds = [1 3 5];
still_conds = [2 4 5];
rc = 3;
if(nVarargs >= 1)
    run_conds = varargin{1};
    if(nVarargs >= 2)
        still_conds = varargin{2};
        if(nVarargs >= 3)
            runthresh = varargin{3};
        end
    end
end
% disp([run_conds still_conds runthresh);
condthr = [.5 1.] ;  %probablility threshold
% length(run_conds)
% run_conds(2)

%rigSpecific  change here for differeence between RPi1 and RPi2
rigSpecific;
RPihost = 'mps-rpi3.cin.ucsf.edu'; %must be set to REAL Rpi name or IP address
RPiport = 8932;
psychstimhost = 'mps-pc37.cin.ucsf.edu'; % runs PsychStimController
runninghost=psychstimhost;
trackballport = 8940;
%End rigspecific

pnet('closeall')  %% why do this--commented out MPS 07/10/2016
% sockm (port 8936) for listening to MouseSender and getting data()
% socsync (port 8939) for listening to PsychStimController for outputfilename and 'close'
% sockrunning (port 8940) used only for sending RUN or STILL to PsychStimController

% define sockets
sockrunning = pnet('udpsocket',runningport); %socket to send output to fPsychStimController
socksync = pnet('udpsocket',trackballport); %socket to listen on for input from PsychStimController
sockm = pnet('udpsocket',RPiport);  %socket to listen on for input from mouse sender
% send start command to RPi
pnet(sockm, 'write', 'start', 'native');
pnet(sockm,'writepacket',RPihost,RPiSelfport);

% pnet(socksync,'setreadtimeout',10);
pnet(sockm,'setreadtimeout',3);

%% setup for real time analysis, socket to send RUNNING = int16(1) or STILL = int16(0)
% to psychstim computer.   MPS 07/10/2016
maxhrs =2;
ti0 = 0;
speed = 0;
lastspeed = speed;
runthresh = 0.5;  %cm/sec
RUNNING = int16(1);
STILL = int16(0);
runorstill = STILL;
dxi = 0;
dyi = 0;
t_int = 0.25;  % 250 msec integration time
runtime = 0.;
stilltime = 0.;
runstim = 0.;
stillstim = 0.;
lastRunChange =0; %used for counting intTime while running/Still
lastStillChange =0;
maxIntTime =2;
%%

dX=zeros(1,60*60*60*maxhrs,'int16');
dY=dX;
dChannel  = dX;
dRunning = dX;
dT = zeros(1,length(dX));
dym1 = 0.;
dym2 = 0.;
dx = 0;


samp = 0;
samp0 = 1;
saveInterval = 10;
printInterval = 30;
nPrints=0;
nSaves=0;

% Create a figure and axes
runstillfig = figure('Visible','on', ...
    'Name','Run Monitor 2', ...
    'MenuBar', 'none','ToolBar','auto', ...
    'Position',[20,500,500,200]);

% Create slider
sldrun = uicontrol('Style', 'slider',...
    'Min',0,'Max',120,'Value',0,...
    'Position', [20 20 400 20]) ;

% Add a text uicontrol to label the slider.
txtrun = uicontrol('Style','text',...
    'Position',[20 45 180 20],...
    'String','Running time (min)');

% Create slider
sldstill = uicontrol('Style', 'slider',...
    'Min',0,'Max',120,'Value',0,...
    'Position', [20 80 400 20]) ;

% Add a text uicontrol to label the slider.
txtstill = uicontrol('Style','text',...
    'Position',[20 105 180 20],...
    'String','Still time (min)');

% Create button
tb = uicontrol(runstillfig,'Style','togglebutton',...
    'String','Waiting for PsychStim',...
    'Value',0,'Position',[20 140 100 30]);

% 	runstillfig.Visible = 'on';

figure(runstillfig); drawnow;

disp('waiting for sync from visual stimulation computer');
rsize = pnet(socksync,'readpacket',80)  %block on this call
ti0 = GetSecs; % making it as close as possible to packet input
disp('sync packet received; started');
outputfilename=pnet(socksync,'read' ,36 );
fname = outputfilename;
disp('Goes into loop. Press ESC to abort');
pnet(sockm,'readpacket'); % reading the package to clear the previous number

while 1
    
    [pressed prtime keycodes] = KbCheck;
    if keycodes(27) == 1 % ESC on Windows Keyboard.
        break;
    end
    
    dsize = pnet(sockm,'readpacket');  %blocks on optical mouse readings, every 2-10 msec
%     data = uint16(pnet(sockm,'read',4,'uint16','native'));
    data = int16(pnet(sockm,'read',4,'int16','native'));
    if dsize ~= 8
        data(2) =1;
        data(3) =0;
        data(4) =0;
    end
    % FOR rpI DATA ARE INT16 'M',1 or 2,dx,dy
    
    % Old format below
    % native = No swapping byte order - use computers native order
    % uint16 = datatype coming in
    % 4 = size of data
    % data(1) is mouse wheeel, insignificant, 256
    % data(2) low byte has mouse number, 0 or 256
    % data(3) high byte has SIGNED byte of x incrmeent dX
    % data(4) low byte has SIGNED y increment dY
    %     disp([data samp]);
    ddm = data(2);
    samp = samp+1;
%     ddm = cast(ddm, 'int16');
    dChannel(samp) = ddm;
     dT(samp)= GetSecs-ti0;
%     ddx =  swapbytes(data(3));
%     ddy =  (data(4));
%     
%     %% new real time segment MPS 07/10/2016
    rm=ddm;  
    rx=data(3);
    ry=data(4);
%     if rx > 127  % signed values for x and y
%         rx = -1*(256-rx)
%     end
%     if ry > 127
%         ry = -1*(256-ry);
%     end
    dX(samp) = data(3);
    dY(samp) = data(4);
    
    %integration time t_int
        % NOT neglect dx = rotation.
        if rm == 1 %from mousex1y1 or mouse x2y2
            dym1 = dym1 + double(ry)^2;
            dx = dx + double(rx)^2;  % imcluding dx .
        else
            dym2 = dym2 + double(ry)^2;
        end
    if dT(samp) > (dT(samp0) + t_int)
        %define the time change, could be more than t_int in reality
        deltaT= dT(samp) - dT(samp0);
        displacement = sqrt(dx+(dym1)+(dym2)); 
        speed = (displacement/tickspercm)/deltaT;
        samp0 = samp;
        disp(sprintf('speed,%6f %6f %6f %6f',dx,dym1,dym2,speed));
        dym1 = 0.;
        dym2 = 0.;
        dx =0.;

%        disp(speed);
        if speed > runthresh   
            runtime = runtime + deltaT;
            runstim = runstim + deltaT*(rc<3);
        else
            stilltime = stilltime + deltaT;
            stillstim = stillstim + deltaT*(rc<3);

        end
    end
%    if speed ~= lastspeed
    if true
%         if speed > runthresh && runorstill == STILL
%         else
%             runorstill = STILL;
%         end
%         
        thr = rand;
        if speed > runthresh
            if (runorstill==STILL ||dT(samp)>=+lastRunChange+maxIntTime)
                if ((thr > condthr(2)) || (runorstill==STILL))
                    rc = 3;
                elseif thr > condthr(1)
                    rc = 2;
                else
                    rc = 1;
                end
                pnet(sockrunning,'write',int16(run_conds(rc)));
                disp(sprintf('running %d',rc));
                tb.ForegroundColor = 'green';
                tb.String = ['Running ' num2str(rc)];
                runorstill = RUNNING;
                if(dT(samp)>=+lastRunChange+maxIntTime)
                    lastRunChange=dT(samp);
                end
                sldrun.Value = runtime/60;
                txtrun.String = ['Run min ' num2str((runtime/60),2) ' Stim: ' num2str((runstim/60),3)];
            end
            lastStillChange = dT(samp); %not Keeping track of still since running
        else
            if (runorstill==RUNNING || dT(samp)>=lastStillChange+maxIntTime)
                if ((thr > condthr(2)) || (runorstill==RUNNING))
                    rc = 3;
                elseif thr > condthr(1)
                    rc = 2;
                else
                    rc = 1;
                end
                pnet(sockrunning,'write',int16(still_conds(rc)));
                disp(sprintf('still %d',rc))
                tb.ForegroundColor = 'red';
                tb.String = ['Still ' num2str(rc)];
                runorstill = STILL;
                if (dT(samp)>=lastStillChange+maxIntTime)
                    lastStillChange =dT(samp);
                end
                sldstill.Value = stilltime/60;
                txtstill.String = ['Still min: ' num2str((stilltime/60),2) ' Stim: ' num2str((stillstim/60),3)];
            end
            lastRunChange =dT(samp);%not keeping track of lastRunChange since still
        end

        pnet(sockrunning,'writepacket', runninghost, runningport);
        lastspeed = speed;
        drawnow;
    end
    dRunning(samp) = runorstill;
    %%end of realtime segment
    
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

% End of running part of the program.
pnet(sockm,'write','stop');
pnet(sockm,'writepacket', RPihost,RPiSelfport);

%% Now store the data and summarize it.
if menu('Save?','Yes','No')==1

	dT = dT(1:samp);
	dChannel = dChannel(1:samp);
	dRunning = dRunning(1:samp);
	dX = dX(1:samp);
	dY = dY(1:samp);

	% trackballfolder now in rigSpecific.m
	pname = [trackballfolder date '\'];
	if exist(pname) ~= 7
	    mkdir(pname);
	end
	outfile = fullfile(pname,[fname '.mat']);
	runningexpt=2-menu('Is this a running expt?','Yes','No');
	save(outfile,'dX','dY','dT','dChannel', 'dRunning','runningexpt','stillstim','runstim');
	disp(['Saved optical mouse data in ' outfile]);
	mouseTrajectory(outfile);
	outfig = fullfile(pname,[fname '.fig']);
	saveas(runstillfig,outfig,'fig');
end

close all;