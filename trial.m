function varargout = PsychStimControllerAnna(varargin)

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @PsychStimController_OpeningFcn, ...
    'gui_OutputFcn',  @PsychStimController_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before PsychStimController is made visible.
function PsychStimController_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to PsychStimController (see VARARGIN)

global moviedirpath paramdirpath kNone ktdtSync ktwoPhoton ktdtUDP kcsUDP ktdsUDP ktdtPT ktdtPTUDP kintan;
% global serialhandle
% Stryker

kNone = 1;
ktdtSync = 2;
ktwoPhoton = 3;
ktdtUDP = 4;
kcsUDP = 5;
ktdsUDP = 6;
ktdtPT = 7;
ktdtPTUDP = 8;
kintan = 9;

%moviedirpath = 'C:\movies\';
%paramdirpath = 'C:\Program Files\MATLAB\R2006b\work\';

moviedirpath = '/Users/visualstim/stimmovies/';
paramdirpath = '/Users/visualstim/stimparams/';


% Choose default command line output for PsychStimController
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes PsychStimController wait for user response (see UIRESUME)
% uiwait(handles.figure1);

ScreenNum_Callback(handles.ScreenNum,eventdata,handles);
StimType_Callback(handles.StimType,eventdata,handles);
Var1_Callback(handles.Var1,eventdata,handles);
Var2_Callback(handles.Var2,eventdata,handles);
Var3_Callback(handles.Var3,eventdata,handles);

% try
%     IOPort('closeall');
%     %serialhandle = IOPort('openserialport', '/dev/tty.usbserial-FTWZCFFD', 'BaudRate=115200');
%     %serialhandle = IOPort('openserialport', '/dev/tty.usbserial-FTWZCFFD');
%     serialhandle = IOPort('openserialport', '/dev/tty.pci-serial3');
%     IOPort('configureserialport', serialhandle, 'RTS=0'); % RTS=0 is 0V.
%
% catch
%     warning('serial port configuration failed')
% end



% --- Outputs from this function are returned to the command line.
function varargout = PsychStimController_OutputFcn(hObject, eventdata, handles) %#ok
varargout{1} = handles.output;


% --- Executes on selection change in StimType.
function StimType_Callback(hObject, eventdata, handles)

StimType = get(hObject,'Value');
%%% disable fields that aren't appropriate to this stimulus type

if ismember(StimType, [1, 6, 8])     %% drifting or counterphase gratings
    set(handles.Duration,'Enable','on');
    set(handles.Speed0,'Enable','off');
    set(handles.TempFreq0,'Enable','on');
    set(handles.Phase0,'Enable','off');
end

if get(handles.mask,'Value') == 1 
    set(handles.PositionX0,'Enable','on');
    set(handles.PositionY0,'Enable','on');
    set(handles.Length0,'Enable','on')
end

if ismember(StimType, [2, 11])     %% drifting bars, moving spots
    ScreenSizeDegX = str2double(get(handles.SizeX,'String')) * ...
        atan(1/str2double(get(handles.ScreenDist,'String'))) * 180/pi;
    Duration = ScreenSizeDegX/str2double(get(handles.Speed0,'String'));
    set(handles.Duration,'String',num2str(Duration));
    set(handles.Duration,'Enable','off');
    set(handles.Speed0,'Enable','on');
    set(handles.TempFreq0,'Enable','off');
end

if StimType==6 %% counterphase gratings
    set(handles.Phase0,'Enable','on');
end

if ismember(StimType, [1, 2, 6, 8, 11, 12, 13]) %% drifting bars, drifting or counterphase gratings, moving spots
    set(handles.Orient0,'Enable','on');
    set(handles.Freq0,'Enable','on');
    set(handles.Contrast0,'Enable','on');
    set(handles.SelectMovieName,'Enable','off');
    set(handles.MovieName,'Enable','off');
    set(handles.MovieMag,'Enable','off');
    set(handles.MovieRate,'Enable','off');
    set(handles.phasePeriod,'Enable','off');
    set(handles.stimulusGroups,'Enable','off');
end

if ismember(StimType, [7, 11, 12, 13]) %% spot or moving spots
    set(handles.PositionX0,'Enable','on');
    set(handles.PositionY0,'Enable','on');
    set(handles.Duration,'Enable','on');
end
if ismember(StimType, [13]) %% Looming Moving Spots
    set(handles.Speed0,'Enable','on');
end



if StimType == 3 %% movie
    set(handles.Orient0,'Enable','off');
    set(handles.Speed0,'Enable','off');
    set(handles.Freq0,'Enable','off');
    set(handles.Contrast0,'Enable','off');
    set(handles.PositionX0,'Enable','on');
    set(handles.PositionY0,'Enable','off');
    set(handles.Duration,'Enable','on');
    set(handles.SelectMovieName,'Enable','on');
    set(handles.MovieName,'Enable','on');
    set(handles.MovieMag,'Enable','on');
    set(handles.MovieRate,'Enable','on');
    set(handles.phasePeriod,'Enable','on');
    set(handles.stimulusGroups,'Enable','on');
    set(handles.TempFreq0,'Enable','off');
    set(handles.Phase0,'Enable','off');
end

if StimType == 3
    % set wait interval to default 0 -- it's too easy to screw this up when
    % showing movies, causing unusual contimage phase behavior -- this is a
    % hack but I don't have better ideas MSC
    set(handles.WaitInterval,'String','0');
end

Var1_Callback(handles.Var1,eventdata,handles);
Var2_Callback(handles.Var2,eventdata,handles);
Var3_Callback(handles.Var3,eventdata,handles);





% --- Executes during object creation, after setting all properties.
function StimType_CreateFcn(hObject, eventdata, handles) %#ok
% hObject    handle to StimType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end







% --- Executes on button press in RunBtn.
function RunBtn_Callback(hObject, eventdata, handles) %#ok
try
    
    % hObject    handle to RunBtn (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % global serialhandle
    % try
    %     IOPort('configureserialport', serialhandle, 'RTS=0'); % RTS=0 is 0V.
    % catch e
    %     e
    % end
    
    
    %clear mex; % what is this for...? shinya
    
    global kNone ktdtSync ktwoPhoton ktdtUDP kcsUDP ktdsUDP ktdtPT ktdtPTUDP kintan; %#ok
    % kcsUDP
    
    %%% load file with rig-specific parameters
    rigSpecific;
    sockrunning = pnet('udpsocket',runningport);

    
    %%% save parameters automatically
    % creat new directory for that day
    if ~exist(date,'dir')
        s = sprintf('mkdir %s',date);
        dos(s);
    end
    % fname = fullfile(date,datestr(clock,30));
    ck=clock(); %  [year month day hour minute seconds]
    filetype='P';
    paramfilename = sprintf('%s_%s_%02d%02d%02d_%02d%02d%02d',filetype,room,...
        ck(1)-2000,ck(2),ck(3),ck(4),ck(5),floor(ck(6)));
    paramfilename = [date '/' paramfilename];
    
    SaveParams(handles,paramfilename);
    
    InitializeMatlabOpenGL;   %%%necessary for OpenGL calls (like ClutBlit)
    
    Screen('Preference','VisualDebugLevel', 1);  %MPS
    
    %%% display description
    Duration = str2double(get(handles.Duration,'String'));
    FrameHz = round(str2double(get(handles.FrameHz,'String')));
    whichScreen = str2double(get(handles.ScreenNum,'String'));
    [window,windowRect]=Screen(whichScreen,'OpenWindow',128);   %%% open grey window

    Screen('FillRect',window,yellow);
    Screen('Flip',window);
end