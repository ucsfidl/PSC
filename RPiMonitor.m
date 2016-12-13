function RPiMonitor
pnet('closeall');
%rigSpecific;
RPihost1 = 'mps-rpi2.cin.ucsf.edu'; %must be set to REAL Rpi name or IP address
RPihost2 = 'mps-rpi3.cin.ucsf.edu'; %must be set to REAL Rpi name or IP address
RPiSelfport = 8888;
RPiport1 = 8931;
RPiport2 = 8932;
%End rigspecific

figH =300;
figW =300;
tab =25;
% Create a figure and axes
Monitorfig = figure('Visible','on', ...
    'Name','Run Monitor.  ESC to terminate', ...
    'MenuBar', 'none','ToolBar','auto', ...
    'Position',[400,200,figW,figH]);

% Mouse1
label_rpi = uicontrol('Style', 'text',...
    'Position', [figW/4 figH-(2*tab) 100 30] ,...
    'String',['Mouse 1 ip:',RPihost1]);

rpi_m1_x = uicontrol('Style','text',...
    'Position',[tab figH-(6*tab) 70 40],...
    'String','X: ');

rpi_m1_y = uicontrol('Style','text',...
    'Position',[figW/2+tab figH-(6*tab) 70 40],...
    'String','Y: ');
rpi_m2_x = uicontrol('Style','text',...
    'Position',[tab figH-(8*tab) 70 40],...
    'String','X: ');

rpi_m2_y = uicontrol('Style','text',...
    'Position',[figW/2+tab figH-(8*tab) 70 40],...
    'String','Y: ');



% Create reset button
resetButton = uicontrol(Monitorfig,'Style','togglebutton',...
    'String','Reset',...
    'Value',0,'Position',[figW/2-3*tab 20 100 30]);

swapButton = uicontrol(Monitorfig,'Style','togglebutton',...
    'String','Swap',...
    'Value',0,'Position',[figW/2-3*tab figH-(3.5*tab) 100 30]);

% 	runstillfig.Visible = 'on';
lastResetVal =resetButton.Value;
lastSwapVal = swapButton.Value;
figure(Monitorfig); drawnow;

pnet('closeall')  %% why do this--commented out MPS 07/10/2016
% define sockets
display('Calling pnet');
sockm1 = pnet('udpsocket',RPiport1);  %socket to listen on for input from mouse sender
sockm2 =pnet('udpsocket',RPiport2);
pnet(sockm1,'setreadtimeout',0.1);
pnet(sockm2,'setreadtimeout',0.1);
% send start command to RPi
pnet(sockm1, 'write', 'start', 'native');
pnet(sockm1,'writepacket',RPihost1,RPiSelfport);
%pnet(sockm2, 'write', 'start', 'native');
%pnet(sockm2,'writepacket',RPihost2,RPiSelfport);
disp('Goes into loop. Press ESC to abort');

intRPi1M1x=int32(0.0);
intRPi1M1y=int32(0.0);
intRPi1M2x=int32(0.0);
intRPi1M2y=int32(0.0);
intRPi2M1x=int32(0.0);
intRPi2M1y=int32(0.0);
intRPi2M2x=int32(0.0);
intRPi2M2y=int32(0.0);

while 1
    if (lastResetVal ~= get(resetButton,'Value'))
        intRPi1M1x=0;
        intRPi1M1y=0;
        intRPi1M2x=0;
        intRPi1M2y=0;
        intRPi2M1x=0;
        intRPi2M1y=0;
        intRPi2M2x=0;
        intRPi2M2y=0;
        disp('resetting')
        lastResetVal = get(resetButton,'Value') ;
        if (lastSwapVal ==0)
             set(rpi_m1_x,'String',['X1: ',num2str(intRPi1M1x)]);
            set(rpi_m1_y,'String',['Y1: ',num2str(intRPi1M1y)]);
            set(rpi_m2_x,'String',['X2: ',num2str(intRPi1M2x)]);
            set(rpi_m2_y,'String',['Y3: ',num2str(intRPi1M2y)]);
        else
            set(rpi_m1_x,'String',['X1: ',num2str(intRPi2M1x)]);
           set(rpi_m1_y,'String',['Y1: ',num2str(intRPi2M1y)]);
           set(rpi_m2_x,'String',['X2: ',num2str(intRPi2M2x)]);
           set(rpi_m2_y,'String',['Y2: ',num2str(intRPi2M2y)]);
 
        end
    end
    if(lastSwapVal~= get(swapButton,'Value'))
        lastSwapVal = get(swapButton,'Value');
        if (lastSwapVal ==0)
            pnet(sockm2, 'write', 'stop', 'native');
            pnet(sockm2,'writepacket',RPihost2,RPiSelfport);
            pnet(sockm1, 'write', 'start', 'native');
            pnet(sockm1,'writepacket',RPihost1,RPiSelfport);
            set(label_rpi,'String',['Mouse 1 ip:',RPihost1]);
            set(rpi_m1_x,'String',['X1: ',num2str(intRPi1M1x)]);
            set(rpi_m1_y,'String',['Y1: ',num2str(intRPi1M1y)]);
            set(rpi_m2_x,'String',['X2: ',num2str(intRPi1M2x)]);
            set(rpi_m2_y,'String',['Y3: ',num2str(intRPi1M2y)]);
            intRPi1M1x
            intRPi1M1y
        else
            pnet(sockm2, 'write', 'start', 'native');
            pnet(sockm2,'writepacket',RPihost2,RPiSelfport);
            pnet(sockm1, 'write', 'stop', 'native');
            pnet(sockm1,'writepacket',RPihost1,RPiSelfport);
            set(label_rpi,'String',['Mouse 2 ip:',RPihost2]);
            set(rpi_m1_x,'String',['X1: ',num2str(intRPi2M1x)]);
           set(rpi_m1_y,'String',['Y1: ',num2str(intRPi2M1y)]);
           set(rpi_m2_x,'String',['X2: ',num2str(intRPi2M2x)]);
           set(rpi_m2_y,'String',['Y2: ',num2str(intRPi2M2y)]);
        end
        
    end
    [pressed prtime keycodes] = KbCheck;
    if keycodes(27) == 1 % ESC on Windows Keyboard.
        break;
    end
    if(get(swapButton,'Value'))
        dsize = pnet(sockm2,'readpacket','noblock');  %blocks on optical mouse readings, every 2-10 msec data = uint16(pnet(sockm,'read',4,'uint16','native'));
    else
        dsize = pnet(sockm1,'readpacket','noblock');
    end
    %disp(dsize);
    if dsize ~= 8
        drawnow;
        continue
    end
    if(get(swapButton,'Value'))
        data = int16(pnet(sockm2,'read',4,'int16','native'));
        if(data(2)==1.0)
           intRPi2M1x = intRPi2M1x+int32(data(3));
            intRPi2M1y = intRPi2M1y+int32(data(4));
        else
           intRPi2M2x = intRPi2M2x+int32(data(3));
            intRPi2M2y = intRPi2M2y+int32(data(4));
        end
        set(rpi_m1_x,'String',['X1: ',num2str(intRPi2M1x)]);
       set(rpi_m1_y,'String',['Y1: ',num2str(intRPi2M1y)]);
       set(rpi_m2_x,'String',['X2: ',num2str(intRPi2M2x)]);
       set(rpi_m2_y,'String',['Y2: ',num2str(intRPi2M2y)]);
    else
        data = int16(pnet(sockm1,'read',4,'int16','native'));
        if(data(2)==1.0)
           intRPi1M1x = intRPi1M1x+int32(data(3));
           
           intRPi1M1y = intRPi1M1y+int32(data(4));
        else
           intRPi1M2x = intRPi1M2x+int32(data(3));
           intRPi1M2y = intRPi1M2y+int32(data(4));
        end
        set(rpi_m1_x,'String',['X1: ',num2str(intRPi1M1x)]);
        set(rpi_m1_y,'String',['Y1: ',num2str(intRPi1M1y)]);
        set(rpi_m2_x,'String',['X2: ',num2str(intRPi1M2x)]);
        set(rpi_m2_y,'String',['Y2: ',num2str(intRPi1M2y)]);
    end
    
   
    %disp(data);
    drawnow;
end
pnet(sockm1,'write','stop');
pnet(sockm1,'writepacket', RPihost1,RPiSelfport);
pnet(sockm2,'write','stop');
pnet(sockm2,'writepacket', RPihost2,RPiSelfport);
pnet('closeall');
close (Monitorfig);
disp('RPiMonitor ended properly');