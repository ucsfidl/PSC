function varargout = PsychStimController(varargin)
% PSYCHSTIMCONTROLLER M-file for PsychStimController.fig
%      PSYCHSTIMCONTROLLER, by itself, creates a new PSYCHSTIMCONTROLLER or raises the existing
%      singleton*.
%
%      H = PSYCHSTIMCONTROLLER returns the handle to a new PSYCHSTIMCONTROLLER or the handle to
%      the existing singleton*.
%
%      PSYCHSTIMCONTROLLER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PSYCHSTIMCONTROLLER.M with the given
%      input arguments.
%
%      PSYCHSTIMCONTROLLER('Property','Value',...) creates a new PSYCHSTIMCONTROLLER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before PsychStimController_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to PsychStimController_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

%% Recent Revisions
% 
% MPS 2016Aug24 Should revise soon to use the calls in ClutAnimDemo to eliminate OpeGL error
% and also to modularize, separating all the synch stuff into different files
% 
% % Pupil and Eye tracker interface MPS 15Aug2016
% Eye tracker Windows Program wants
% Filename at the start
% then for each pupil image to be saved, a single 32-bit float 
% that is the timestamp in seconds from the start of recording.
% Current CPP_Snapsohot program works only for intervals > 65 msec.  
% I will plan to take a pupil image every 6 frames, which will
% give us pupil images at 10 Hz.
% To stop the pupil program, send a floating -1.

% Rapid switching of stimulus for control by locomotion state MPS 08Aug2016
% UDP input to runningport will be stimulus number. 
% The display screen switches immediately to the 
% beginning of the selected stimulus 
% SimUDP call lets you switch by hand just by typing a number.
% ESC terminates the program.

%%
% 01/07/13 darcy:
% added SyncSource to list of saved variables
% fixed bug 'lutMax = sizeLut-1' in generateBar_lut.m, line 37, that was
% causing a single frame flash with sweeping bars of length other than 0

% With kintan and UDP synchronization, we have bit 1 of UDP2TTL going up
% with each stimulus, adn bit 2 beign strobed with each frame
% this is different from kintan and LPT synch, where there is only one bit
% that stays up throughout entire run.

%% To Do Soon (Stryker 2 Sep 2009)
%If one of the variables is EYE, then add extra condidions
%   a background and
%   a full field flicker
%   for each value of the EYE variable
%
% Make the movies read their parameters, including at least
%         their minor period,
%         their category period, (or major period, potentially 0 if the movie is all the same)
%         their intended frame rate and magnification,
%         theirr sptial ant temporal frequency bands
%
% 	Add a stimulus type of MovieSegment ,
%         which would index into a movie and display different segments of it,
%         respecting by default the periodic nature of the movie
%
% Recently Done:
%     Added a third variable (with corresponding modifications to the TDT adn UDP code)
%     so as to permit things like orientation, spatial frequency, and eye
%
%     Added a List series type, so that you can just type in the values of a variable that you want,
%     rather than specifying start stop and nsteps.
%
%     Folded the previously distinct lookup table animation (clut)
%         and frame blit (movie) animations into a single loop,
%         which allows the synchronization code to appear only once.
%
%
%%
% Copyright 2002-2003 The MathWorks, Inc.

% Edit the above text to modify the response to help PsychStimController

% Last Modified by GUIDE v2.5 27-Feb-2015 12:59:33

% Begin initialization code - DO NOT EDIT
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
    
    imageRect = windowRect;
    Screen('DrawText',window,sprintf('Generating stimuli'),10,30);
    Screen('Flip',window);
    
    ScreenSizeDegX = str2double(get(handles.SizeX,'String'))*atan(1/str2double(get(handles.ScreenDist,'String')))*180/pi;
    global degPerPix xwinpix ywinpix azcp elcp;
    degPerPix = ScreenSizeDegX/windowRect(3);
    xwinpix = windowRect(3);
    ywinpix = windowRect(4);
    azcp = str2double(get(handles.cp_azdeg,'String'));
    elcp = str2double(get(handles.cp_eldeg,'String'));
    
    
    
    white = WhiteIndex(window);
    black = BlackIndex(window);
    grey = round(0.5*(black+white));
    
    nCond = size(handles.orient,2)
    stim = get(handles.StimType,'Value');
    
    % nReps is the number of repetitions of the entire stimulus sequence
    % fractional values of nReps are useful to truncate movies
    nReps = str2double(get(handles.nReps,'String'));
    if nReps <= 0 %% loop almost-infinitely
        nReps = 10000000;
    end
    
    nStimulusRepetitions = 1; % defaults to 1 for non-movie stimuli
    
    backlum = str2num(get(handles.BackLum,'String'));
    
    % darcy: map backlum (-1 to 1) onto white to black range
    backlum = round(((white-black)*(backlum+1))/2);
    
    % darcy: this references the 'contrast' guide field.
    contrast=handles.contrast(1);
    
    %%%for clut animation
    if ismember(stim, [1 4 5 6 8]) % [drift gratings, flash, checkerboard, c-phase gratings]
        clut=1;
        sizeLut=256;
        offclut=zeros(sizeLut,3);
        offclut(:,:)=grey;   %default
    elseif ismember(stim, [2 7 11 12 13])  %% for bars and spots and moving spots
        clut=1;
        sizeLut=256;
        offclut=zeros(sizeLut,3);
        offclut(:,:)=backlum;
        
        %     blankimage = zeros(imageRect(3),imageRect(4));
        %     blanktexture(1,1) = Screen('MakeTexture',window,blankimage);
    else %% stim == 3 or 12 or 13
        clut=0;
    end
    
    %% stimulus construction lines ~390-890
    switch stim
       
        %%%%%%  drifting, counterphase
        case {1,6,8}
            % screen_gamma=2;
            textures = zeros(nCond,1);
            maskTexture = zeros(nCond,1);
            for c = 1:nCond
                c
                if get(handles.StimType,'Value')==1   %%% drift gratings
                    [img cl] = generateGratings_lut(handles.orient(c),handles.freq(c),handles.TempFreq(c),handles.phase(c),handles.contrast(c),Duration, degPerPix,imageRect(3),imageRect(4),FrameHz,black,white,sizeLut);
                elseif get(handles.StimType,'Value')==6 % counterphase gratings
                    [img cl] = generateCPGratings_lut(handles.orient(c),handles.freq(c),handles.TempFreq(c),handles.phase(c),handles.contrast(c),Duration, degPerPix,imageRect(3),imageRect(4),FrameHz,black,white,sizeLut);
                elseif get(handles.StimType,'Value')==8   %%% reverse drift gratings
                    [img cl] = generateReverseGratings_lut(handles.orient(c),handles.freq(c),handles.TempFreq(c),handles.phase(c),handles.contrast(c),Duration, degPerPix,imageRect(3),imageRect(4),FrameHz,black,white,sizeLut);
                end
                % masked stim?
                if get(handles.mask,'Value') ==1
                    szXcm = str2double(get(handles.SizeX,'String'));
                    szYcm = str2double(get(handles.SizeY,'String'));
                    cpx_cm = str2double(get(handles.cpx_cm,'String'));
                    cpy_cm = str2double(get(handles.cpy_cm,'String'));
                    [mask] = generateMask(handles.length(c),degPerPix,imageRect(3),imageRect(4),black,white,handles.positionX(c),handles.positionY(c),cpx_cm,cpy_cm,azcp,elcp,szXcm,szYcm);
                end
                
                fprintf('done generating')
                if c==1
                    cluts = zeros(256,3,size(cl,3),nCond);
                end
                cluts(:,:,:,c)=floor(cl);
                textures(c,1)=Screen('MakeTexture',window,img);
                if get(handles.mask,'Value')==1
                    maskTexture(c) = Screen('MakeTexture', window, mask);
                end
            end %cond
            FrameWait=1;
            
            % Change clut for square gratings
            if (get(handles.squaregratings,'Value'))
                cluts(cluts < 127) = 0;
                cluts(cluts >= 128) = 255;
            end
            
            %%%%% checkerboard  %%%%%%%%%%
        case 5
            nCond = size(handles.freq,2);
            textures = zeros(nCond,1);
            for c = 1:nCond
                [x y]= meshgrid(1:imageRect(3), 1:imageRect(4));
                contrast = handles.contrast(c);
                f= 2*pi*handles.freq(c)* degPerPix;
                img = 1+sign(sin(f*x).*sin(f*y));
                if contrast>1
                    contrast=1;
                end
                
                inc=(white-grey)*contrast;
                
                cl = offclut;
                cl(1,:) = grey-inc;
                cl(2,:) = grey+inc;
                cl(3,:) = grey+inc;
                
                fprintf('done generating')
                if c==1
                    cluts = zeros(256,3,size(cl,3),nCond);
                end
                cluts(:,:,:,c)=floor(cl);
                textures(c,1)=Screen('MakeTexture',window,img);
            end
            FrameWait = ceil(Duration*FrameHz);
            
            %%%%%%%  fullfield flash %%%%%%%%
        case 4 %
            offclut(:,:)=black;
            textures = zeros(nCond,1);
            for c = 1:nCond
                img = ones(imageRect(4), imageRect(3));
                cl  = offclut;
                cl(:,:) = floor(white*handles.contrast(c));
                fprintf('done generating')
                if c==1
                    cluts = zeros(256,3,size(cl,3),nCond);
                end
                cluts(:,:,:,c)=floor(cl);
                textures(c,1)=Screen('MakeTexture',window,img);
            end % cond
            FrameWait = ceil(Duration*FrameHz);
            
            %%%%% moving spots  %%%%%
        case 11
            
            cpx_cm = str2double(get(handles.cpx_cm,'String'));
            cpy_cm = str2double(get(handles.cpy_cm,'String'));
            SizeX = str2double(get(handles.SizeX,'String'));
            SizeY = str2double(get(handles.SizeY,'String'));
            
            
            
            
            textures = zeros(nCond, 1);
            for c = 1:nCond
                
                xposdeg = handles.positionX(c);
                yposdeg = handles.positionY(c);
                posXpix = (((cpx_cm/SizeX)*xwinpix) + xposdeg/degPerPix) - (azcp/degPerPix);
                posYpix = (((cpy_cm/SizeY)*ywinpix) - yposdeg/degPerPix) - (elcp/degPerPix);
                
                [img cl] = generateMovingSpots_lut(handles.orient(c),handles.freq(c),handles.speed(c),handles.contrast(c),handles.length(c), posXpix, posYpix,Duration, degPerPix,imageRect(3),imageRect(4),FrameHz,black,white,sizeLut,backlum);
                fprintf('done generating')
                if c==1
                    cluts = zeros(256, 3, size(cl, 3), nCond);
                end
                cluts(:,:,:,c) = floor(cl);
                if (get(handles.DoNearScreen,'Value'))
                    fprintf('DoNearScreen')
                    %Now set  in dialog box: cp_azdeg=45; cp_eldeg=0; cpx_cm=20; cpy_cm=20;
                    img3 = NearScreen(img, str2double(get(handles.cp_azdeg,'String')), str2double(get(handles.cp_eldeg,'String')), ...
                        str2double(get(handles.ScreenDist,'String')), str2double(get(handles.cpx_cm,'String')), str2double(get(handles.cpy_cm,'String')), ...
                        degPerPix, imageRect(3), imageRect(4), imageRect(3)/str2double(get(handles.SizeX,'String')), ...
                        str2double(get(handles.SizeX,'String')),str2double(get(handles.SizeY,'String')) );
                    %             cp_azdeg=45; cp_eldeg=0; cpx_cm=20; cpy_cm=20; %Set these in dialog box
                    %             img3 = NearScreen(img, cp_azdeg, cp_eldeg, str2double(get(handles.ScreenDist,'String')), cpx_cm, cpy_cm, ...
                    %                 degPerPix, imageRect(3), imageRect(4), imageRect(3)/str2double(get(handles.SizeX,'String')), ...
                    %                 str2double(get(handles.SizeX,'String')),str2double(get(handles.SizeY,'String')) );
                    textures(c,1)=Screen('MakeTexture',window,img3);
                else
                    textures(c,1)=Screen('MakeTexture',window,img);
                end
                % black background
                %offclut(:) = grey - (white-grey)*handles.contrast(c);
            end % cond
            FrameWait = 1;
            
            
            %%%%% drifting bars  %%%%%
        case 2
            textures = zeros(nCond,1);
            for c = 1:nCond
                %           frm = generateBars_blit(handles.orient(c),handles.freq(c),handles.speed(c),handles.contrast(c),handles.length(c), handles.positionX(c),Duration, degPerPix,imageRect(3),imageRect(4),FrameHz,black,white,2048);
                %         nFrames = size(frm,1);
                %         for f = 1:nFrames
                %              textures(c,f)=Screen('MakeTexture',window,squeeze(frm(f,:,:)));
                %         end
                %         MovieRate = FrameHz;
                %         destRect = windowRect;
                %         clut=0;
                %         if c==1
                %             save frames frm
                %         end
                %[img cl] = generateBars_lut(handles.orient(c),handles.freq(c),handles.speed(c),handles.contrast(c),handles.length(c), handles.positionX(c),Duration, degPerPix,imageRect(3),imageRect(4),FrameHz,black,white,sizeLut,backlum);
                [img cl] = generateBars_lut(handles.orient(c),handles.freq(c),handles.speed(c),handles.contrast(c),handles.length(c), handles.positionX(c),Duration, degPerPix,imageRect(3),imageRect(4),FrameHz,black,white,sizeLut,backlum);
                fprintf('done generating')
                if c==1
                    cluts = zeros(256,3,size(cl,3),nCond);
                end
                cluts(:,:,:,c)=floor(cl);
                % Stryker NearScreen correction:  Set DoNearScreen = 1; and set the aximuth
                % and elevation of the closest point on the screen, and the postiion of the
                % closest point on the screen measured from the top left corner in cm
                % by setting cp_azdeg=0; cp_eldeg=0; cpx_cm=20; cpy_cm=20;
                % Future fix will set them in a dialog box, but it works now for the bar
                % stimuli at all distances tried.
                % DoNearScreen = 1;
                if (get(handles.DoNearScreen,'Value'))
                    fprintf('DoNearScreen')
                    %Now set  in dialog box: cp_azdeg=45; cp_eldeg=0; cpx_cm=20; cpy_cm=20;
                    img3 = NearScreen(img, str2double(get(handles.cp_azdeg,'String')), str2double(get(handles.cp_eldeg,'String')), ...
                        str2double(get(handles.ScreenDist,'String')), str2double(get(handles.cpx_cm,'String')), str2double(get(handles.cpy_cm,'String')), ...
                        degPerPix, imageRect(3), imageRect(4), imageRect(3)/str2double(get(handles.SizeX,'String')), ...
                        str2double(get(handles.SizeX,'String')),str2double(get(handles.SizeY,'String')) );
                    %             cp_azdeg=45; cp_eldeg=0; cpx_cm=20; cpy_cm=20; %Set these in dialog box
                    %             img3 = NearScreen(img, cp_azdeg, cp_eldeg, str2double(get(handles.ScreenDist,'String')), cpx_cm, cpy_cm, ...
                    %                 degPerPix, imageRect(3), imageRect(4), imageRect(3)/str2double(get(handles.SizeX,'String')), ...
                    %                 str2double(get(handles.SizeX,'String')),str2double(get(handles.SizeY,'String')) );
                    textures(c,1)=Screen('MakeTexture',window,img3);
                else
                    textures(c,1)=Screen('MakeTexture',window,img);
                end
                % black background
                %offclut(:) = grey - (white-grey)*handles.contrast(c);
            end % cond
            FrameWait = 1;
            
            
            %%%%% looming spots %%%%% 9/5/2014 Shinya
        case 12
            cpx_cm = str2double(get(handles.cpx_cm,'String'));
            cpy_cm = str2double(get(handles.cpy_cm,'String'));
            SizeX = str2double(get(handles.SizeX,'String'));
            SizeY = str2double(get(handles.SizeY,'String'));
            
            nCond = size(handles.freq,2);
            textures = zeros(nCond, 1);
            for c = 1:nCond
                xposdeg = handles.positionX(c);
                yposdeg = handles.positionY(c);
                posXpix = (((cpx_cm/SizeX)*xwinpix) + xposdeg/degPerPix) - (azcp/degPerPix);
                posYpix = (((cpy_cm/SizeY)*ywinpix) - yposdeg/degPerPix) - (elcp/degPerPix);
                
                contrast = handles.contrast(c);
                widthPix = handles.length(c)/degPerPix;
                
                
                % add something here to create circle with various sizes
                
                % **needed parameters (from Yilmaz & Meister, 2013)
                % min diameter 2 deg
                % max diameter 20 deg (length)
                % velocity 35 degs/s (speed)
                % expanding duration 250ms (1/2 duration)
                % total duration 500ms (duration)
                % wait interval 500ms
                % contrast -1
                
                %cir= Circle(floor(widthPix)/2);
                %mindia = floor(widthPix / 10);
                %cirmin = Circle(mindia);
                
                cone = Cone2D(floor(widthPix), floor(widthPix/10));
                
                
                img = zeros(imageRect(4),imageRect(3),'double');
                for xk = 1:size(cone,1)
                    for yk = 1:size(cone,2)
                        % darcy: min allowed point is img(1,1)
                        %img(max(yk+floor(posYpix-widthPix/2),1),max(xk+floor(posXpix-widthPix/2),1)) = double(cir(xk,yk));
                        img(max(yk+floor(posYpix-widthPix/2),1),max(xk+floor(posXpix-widthPix/2),1)) = double(cone(xk,yk));
                    end
                end
                
                if contrast > 1
                    contrast = 1;
                elseif contrast < -1
                    contrast = -1;
                end
                inc = (white-grey)*contrast;
                framenum = Duration * FrameHz;
                cl = repmat(offclut,[1,1,framenum]);
                for i = 1:framenum / 2
                    % when i is framenum/2, only cl(255
                    cl(end:-1:max(2,end-floor(end*(i/framenum*2))),:,i) = grey+inc;
                end
                for i = framenum/2:framenum
                    cl(2:end,:,i) = grey+inc;
                end
                %cl(1,:,:) = grey;
                %cl(2:end,:) = grey + inc;
                %cl = repmat(cl,[1, 1, 30]);
                
                
                fprintf('done generating')
                
                if c==1
                    cluts = zeros(256,3,size(cl,3),nCond);
                end
                cluts(:,:,:,c)=floor(cl);
                textures(c,1)=Screen('MakeTexture',window,img);
            end % cond
            %FrameWait = ceil(Duration*FrameHz);
            FrameWait = 1;
            
            
            
            %%% flashing spots  %%%%%%%
        case 7
            %darcy - should all these repeated 'gets' be put in one place at the
            %top?
            cpx_cm = str2double(get(handles.cpx_cm,'String'));
            cpy_cm = str2double(get(handles.cpy_cm,'String'));
            SizeX = str2double(get(handles.SizeX,'String'));
            SizeY = str2double(get(handles.SizeY,'String'));
            
            nCond = size(handles.freq,2);  %% what is this??
            textures = zeros(nCond,1);
            for c = 1:nCond
                [x y]= meshgrid(1:imageRect(3), 1:imageRect(4));
                contrast = handles.contrast(c);
                widthPix = handles.length(c)/degPerPix;
                
                % darcy: added cpx_cm & azcp, etc.
                
                % pixels to degrees, code from handmapping
                %             xposdeg = ((xpos-((cpx_cm/SizeX)*xwinpix))*degPerPix) + azcp;
                %             yposdeg = (-1*((ypos-((cpy_cm/SizeY)*ywinpix))*degPerPix)) + elcp;
                
                % original
                % posXpix = (floor(imageRect(3)/2) + handles.positionX(c)/degPerPix);
                % posYpix = (floor(imageRect(4)/2) + handles.positionY(c)/degPerPix);
                
                xposdeg = handles.positionX(c);
                yposdeg = handles.positionY(c);
                
                posXpix = (((cpx_cm/SizeX)*xwinpix) + xposdeg/degPerPix) - (azcp/degPerPix);
                posYpix = (((cpy_cm/SizeY)*ywinpix) - yposdeg/degPerPix) - (elcp/degPerPix);
                
                % Stryker change to make round spots 2012-Jan-30
                SquareSpots =  (get(handles.squaregratings,'Value'))
                if SquareSpots
                    img = double((x>(posXpix-widthPix/2)) & (x<(posXpix+widthPix/2)) & (y>(posYpix-widthPix/2)) & (y<(posYpix+widthPix/2)));
                else
                    cir= Circle(floor(widthPix)/2);
                    img = zeros(imageRect(4),imageRect(3),'double');
                    for xk = 1:size(cir,1)
                        for yk = 1:size(cir,2)
                            % darcy: min allowed point is img(1,1)
                            img(max(yk+floor(posYpix-widthPix/2),1),max(xk+floor(posXpix-widthPix/2),1)) = double(cir(xk,yk));
                        end
                    end
                end
                
                
                if contrast > 1
                    contrast = 1;
                elseif contrast < -1
                    contrast = -1;
                end
                inc = (white-grey)*contrast;
                cl = offclut;
                cl(2,:) = grey+inc;
                
                flickfreq = handles.TempFreq(c);
                
                
                if flickfreq ~= 0
                    flickperiod = 1/flickfreq * FrameHz; % number of frames
                    flickerdur = flickperiod / 2;
                    
                    TotalFNum = Duration * FrameHz;
                    numrep = round(TotalFNum / flickperiod);
                    
                    cl(:,:,2) = grey;
                    cl = repmat(cl, [1, 1, numrep]);
                else
                    flickerdur = Duration * FrameHz;
                end
                
                
                if c==1
                    cluts = zeros(256,3,size(cl,3),nCond);
                end
                cluts(:,:,:,c)=floor(cl);
                textures(c,1)=Screen('MakeTexture',window,img);
            end % cond
            fprintf('done generating')
            
            FrameWait = ceil(flickerdur);
            
            
            
            %MoLo Spots% Isaiah Discipulo 10.26.2014
        case 13
            
            cpx_cm = str2double(get(handles.cpx_cm,'String'));
            cpy_cm = str2double(get(handles.cpy_cm,'String'));
            SizeX = str2double(get(handles.SizeX,'String'));
            SizeY = str2double(get(handles.SizeY,'String'));
            deg = str2double(get(handles.Orient0, 'String'));
            
            nCond = size(handles.freq,2);
            textures = zeros(nCond, 1);
            for c = 1:nCond
                xposdeg = handles.positionX(c);
                yposdeg = handles.positionY(c);
                posXpix = (((cpx_cm/SizeX)*xwinpix) + xposdeg/degPerPix) - (azcp/degPerPix);
                posYpix = (((cpy_cm/SizeY)*ywinpix) - yposdeg/degPerPix) - (elcp/degPerPix);
                
                deg = handles.orient(c);
                molospeed = handles.speed(c);
                shift = molospeed * Duration / degPerPix;
                
                
                contrast = handles.contrast(c);
                widthPix = handles.length(c)/degPerPix;
                
                
                % add something here to create circle with various sizes
                
                % **needed parameters (from Yilmaz & Meister, 2013)
                % min diameter 2 deg
                % max diameter 20 deg (length)
                % velocity 35 degs/s (speed)
                % expanding duration 250ms (1/2 duration)
                % total duration 500ms (duration)
                % wait interval 500ms
                % contrast -1
                
                %cir= Circle(floor(widthPix)/2);
                %mindia = floor(widthPix / 10);
                %cirmin = Circle(mindia);
                
                %MoLo = generateMoLo(floor(widthPix/10), floor(widthPix), shift, round(Duration * FrameHz), deg);
                MoLo = generateMoLo(floor(widthPix/10/2), floor(widthPix)/2, shift, 256, deg);
                
                
                img = zeros(imageRect(4),imageRect(3),'double');
                for xk = 1:size(MoLo,1)
                    for yk = 1:size(MoLo,2)
                        % darcy: min allowed point is img(1,1)
                        %img(max(yk+floor(posYpix-widthPix/2),1),max(xk+floor(posXpix-widthPix/2),1)) = double(cir(xk,yk));
                        img(max(yk+floor(posYpix-widthPix/2),1),max(xk+floor(posXpix-widthPix/2),1)) = double(MoLo(xk,yk));
                    end
                end
                
                if contrast > 1
                    contrast = 1;
                elseif contrast < -1
                    contrast = -1;
                end
                inc = (white-grey)*contrast;
                framenum = Duration * FrameHz;
                cl = repmat(offclut,[1,1,framenum]);
                for i = 1:framenum / 2
                    % when i is framenum/2, only cl(255
                    cl(end:-1:max(2,end-floor(end*(i/framenum*2))),:,i) = grey+inc;
                end
                for i = framenum/2:framenum
                    cl(2:end,:,i) = grey+inc;
                end
                %cl(1,:,:) = grey;
                %cl(2:end,:) = grey + inc;
                %cl = repmat(cl,[1, 1, 30]);
                
                
                fprintf('done generating')
                
                if c==1
                    cluts = zeros(256,3,size(cl,3),nCond);
                end
                cluts(:,:,:,c)=floor(cl);
                textures(c,1)=Screen('MakeTexture',window,img);
            end % cond
            %FrameWait = ceil(Duration*FrameHz);
            FrameWait = 1;
            
            %%%%% movie %%%%%
        case 3
            load(get(handles.MovieName,'String'),'moviedata');
            
            MovieMag = str2double(get(handles.MovieMag,'String'));
            MovieRate = str2double(get(handles.MovieRate,'String'));
            phasePeriod = str2double(get(handles.phasePeriod,'String'));
            
            % done loading movie
            
            length = str2double(get(handles.Length0,'String'));
            if length > 0
                length = length/MovieMag;
                length = length/degPerPix;
                moviedata = moviedata(1:round(length),:,:); %#ok
            end
            
            nFrames = size(moviedata,3);
            
            % fractional nReps truncates movie
            if (nReps < 1)
                nFrames = min(nFrames,floor(nFrames*nReps));
                nReps = 100000000;  %%%%% fix this
            else
                nFrames = min(nFrames,ceil(Duration*MovieRate));
            end
            
            %% if multiple stimulus groups specified, break up movies into different stimulus conditions
            % period of the stimulus (i.e. one phase cycle)
            phasePeriodFrames = MovieRate * phasePeriod;
            if phasePeriodFrames == 0
                phasePeriodFrames = nFrames;
            end
            
            % number of different stimulus groups contained in movie, default 1
            % this does not constrain the number of repetitions in a group, which
            % is set by Duration and phasePeriodFrames
            stimgroups =str2double(get(handles.stimulusGroups,'String'));
            nCond = stimgroups;
            if nCond > 1
                % number of repetitions of each stimulus in one group
                nStimulusRepetitions = (nFrames/phasePeriodFrames) / nCond;
                disp(sprintf('%.1f conditions, %.1f stimuli per condition',nCond,nStimulusRepetitions));
                if (nStimulusRepetitions ~= floor(nStimulusRepetitions)) % must be integer
                    error('Movie not evenly divisible; is number of stimulus groups wrong?');
                end
            else
                nCond = size(handles.freq,2);   %%% if only one stimulus group, then use variables to set nCond
            end
            
            imageRect = SetRect(0,0,size(moviedata,1),size(moviedata,2));
            destRect = CenterRect(MovieMag*imageRect,windowRect);
            x0 = str2double(get(handles.PositionX0,'String'));
            if x0 ~= 0
                dx = x0/degPerPix;
                destRect = OffsetRect(destRect,dx,0);
            end
            
            textures = zeros(1,nFrames);
            for f=1:nFrames
                textures(1,f)=Screen('MakeTexture',window,squeeze(moviedata(:,:,f))');
            end
            clear moviedata
            
            FrameWait = FrameHz/MovieRate;
            
    end % of switch stim
    
    %% gamma correction
    screen_gamma=1.83
    flat_clut = [(0:1/255:1)' (0:1/255:1)' (0:1/255:1)'];
    gamma_clut = flat_clut.^(1/screen_gamma);
    Screen('LoadNormalizedGammaTable',window,gamma_clut);
    %Screen('LoadNormalizedGammaTable',window,flat_clut);
    
    %% clear screen --
    Screen('FillRect',window,grey);
    Screen('DrawText',window,sprintf('Finished stimuli'),10,40);
    Screen('Flip',window);
    
    %% get number of frames
    if clut
        nFrames = size(cluts,3);
    elseif stim == 3  %% ie, not clut (to prevent error with hand mapping)
        nFrames = size(textures,2);
    end
    
    %% setup synchronization
    
    %%send filename to eyecam
    eyecamsock = pnet('udpsocket',8933);
	eyecam_filename = sprintf('%s_%s_%02d%02d%02d_%02d%02d%02d','E',room,...
            ck(1)-2000,ck(2),ck(3),ck(4),ck(5),floor(ck(6)));
	eyecam_filename = ['C:\bin\30-Aug-2016\data003\' eyecam_filename]
	% eyecammhost and port are now defined in rig_specific.m  
    eyecamsock = pnet('udpsocket',8933);
	pnet(eyecamsock,'write',sprintf('%s', eyecam_filename));
	pnet(eyecamsock,'writepacket', eyecamhost, eyecamport);

    stopudp = pnet('udpsocket',3787);
    statusfile = fopen('statusfile.txt','w');
    startTime = GetSecs();
    
    sync = get(handles.SyncSource,'Value');
    tic;
    if sync == ktdtSync
        dio = digitalio('parallel','LPT1');
        % hwline = addline(dio,0:1,2,'out','bitLine');    %% pins 1,14
        addline(dio,0:7,'out'); %% pins 2-9
        
        %%% for some reason, the slowest part of putvalue when using parallel port
        %%% is this step, finding the parent uddobj.
        %%% So we look this up in the beginning, and then directly call the
        %%% putvalue function with uddobject, data, and line numbers.
        %%% Not exactly sure why this works, but it reduces time per call
        %%% from 2msec to 20usec (at least in previous versions of daqtoolbox
        parent = get(dio.bitLine, 'Parent');
        parentuddobj = daqgetfield(parent{1},'uddobject');
        % stimLine = 1;
        % frameLine = 2;
        bitLine=1:2;
        condNum=3:10;
        bitOn=0;
        bitOff=1;
        putvalue(parentuddobj,0,condNum);
        putvalue(parentuddobj,[bitOff bitOff],bitLine);
    elseif sync == ktdsUDP
        syncTDSUdp=pnet('udpsocket',1111);
        syncTDSHost = shutterHost;
        syncTDSPort = shutterPort;
    elseif sync == ktdtUDP
        syncUdp=pnet('udpsocket',1111);
        syncHost = tdtHost;
        syncPort = tdtPort;
    elseif sync == kcsUDP
        syncUdp=pnet('udpsocket',1111);
        syncHost = contImageHost
        syncPort = contImagePort
        % strComm = 'sy';
        % udpChannel = uint16(0);
        phMax = 65535;
    elseif sync == ktdtPT
        lptwrite(888,0);
        %%% To set this write [StimLine + (2 * framelLine) + (4 * condNum) ]
        %%% masked to 8 bits
    elseif sync == ktdtPTUDP
        lptwrite(888,0);
        syncUdp=pnet('udpsocket',1111);
        syncHost = tdtHost;
        syncPort = tdtPort;
    elseif sync == kintan
        %stimsync conditional added MPS 2105Jan06
       if stimsync == 'LPT'
        %lptwrite(888,0); % < - commented out by MCD 2015
        lptwrite(888,1); % triggers recording in intan
       elseif stimsync == 'SER'
        IOPort('configureserialport', serialhandle, 'RTS=0'); % RTS=0 is 0V.
       else  %stimsync == 'UDP'
        stimsyncUdp = pnet('udpsocket',1113);
        pnet(stimsyncUdp, 'write', uint8(0));
        pnet(stimsyncUdp, 'writepacket', stimsynchost, stimsyncport);
       end
        syncUdp=pnet('udpsocket',1111);
        syncHost = tdtHost;
        syncPort = tdtPort;
        phMax = 65535;
        intanSyncData = [];
        %% begin MPS 2014-07-14
        % syncfilename = datestr(now, 'mmmm-dd-yyyy_HH_MM_SS');
        %ck=clock(); % should have defined already at paramfilename definition
        filetype='I';
        syncfilename = sprintf('%s_%s_%02d%02d%02d_%02d%02d%02d',filetype,room,...
            ck(1)-2000,ck(2),ck(3),ck(4),ck(5),floor(ck(6)));
        syncfilename = [date '/' syncfilename];
        
        trackball_syncfilename = sprintf('%s_%s_%02d%02d%02d_%02d%02d%02d','T',room,...
            ck(1)-2000,ck(2),ck(3),ck(4),ck(5),floor(ck(6)))
       %trackball_syncfilename = [date '/' trackball_syncfilename];
         % trackballhost and port are now defined in rig_specific.m  trackballhost='mps-pc7.cin.ucsf.edu';
        trackballsocket = pnet('udpsocket',1112);
        pnet(trackballsocket,'write',sprintf('%s', trackball_syncfilename));
        pnet(trackballsocket,'writepacket', trackballhost, trackballport);
        %% end MPS 2014-07-14
        startTime=GetSecs;
    end
    
    % shutterHost = 'mps-d.ucsf.edu'
    % shutterPort = 2424
    % This sets the port A direction to all-outputs
    % PortA controls shutter
    % PortB connects to low byte of RX/RZ DIO for Condition Number
    % PortC connects to bits 3:4 of RX/RZ DIO for Stimline:Frameline
    % Stimline is PortC & 0x10=16; Frameline is PortC & 0x20=32
    % These set port direction
    shutterUdp = pnet('udpsocket',1111);
    pnet(shutterUdp,'write',sprintf('!A%c',0));
    pnet(shutterUdp,'writepacket',shutterHost,shutterPort);
    pnet(shutterUdp,'write',sprintf('!B%c',0));
    pnet(shutterUdp,'writepacket',shutterHost,shutterPort);
    pnet(shutterUdp,'write',sprintf('!C%c',207)); % = !1100 1111
    pnet(shutterUdp,'writepacket',shutterHost,shutterPort);
    
    %% set background clut
    if clut
        moglClutBlit(window,textures(1),offclut);
        %    moglClutBlit(window,blanktexture,offclut);
        % currentclut=offclut;
    end
    
    clearBkgrnd = get(handles.bkgrnd,'Value');
    
    stimConds = nCond;
    blankCond = 0;
    flickCond = 0;
    
    %% add blank stimulus as extra condition
    if get(handles.blankstim,'Value')
        if clut
            nCond = nCond + 1;
            cluts(:,:,:,nCond) = offclut(1,1);
            
            % darcy - use below to set blank to same color as background
            % for bars w/ contrast = 1 or contrast = -1 (otherwise blank stim is grey)
            % cluts(:,:,:,nCond) = grey - (white-grey)*handles.contrast(c);
            % cluts(:,:,:,nCond) = offclutval;
            
            textures(nCond) = textures(nCond-1);
            handles.eye(nCond)= 3; %%% NOTE!!! Blank stimulus only for both eyes!
            blankCond = -1;
        else  %%% no need for blank in movies (at least for now)
            sprintf('no blank available for movies')
        end
    end
    
    %% add full field flicker as extra condition, for drifiting gratings
    if get(handles.FullFlicker,'Value') && (get(handles.StimType,'Value')==1)
        % Cris had the nCond=nCond+1 here.  This seems tobe a mistake, and we have
        % moved it into the if statement
        if clut
            nCond = nCond + 1;
            cluts(:,:,:,nCond)=cluts(:,:,:,1);
            textures(nCond)=Screen('MakeTexture',window,ones(size(img)));
            handles.eye(nCond)= 3; %%% NOTE!!! Flicker stimulus only for both eyes!
            flickCond = -2;
        else  %%% no need for blank in movies (at least for now)
            sprintf('no blank available for movies')
        end
        
    end
    
    %% set up run variables
    if stim == 10 || stim == 15
        nFrames = 2;
    end
    
    FrameInt = 1/FrameHz;
    WaitInt = str2double(get(handles.WaitInterval,'String'));
    
    s1 = zeros(nFrames,1);
    ds = zeros(nFrames-1,1);
    
    texturec = 1;
    
    %% finally, run stimulus!!
    warning off MATLAB:concatenation:integerInteraction  %%%% this error comes up in generating udp packet
    try %% put this is a try/catch, so that any crash won't leave screen hung
        ListenChar(2);
        
        % Make sure all Rushed variables and functions are in memory
        % before raising priority
        doneStim = 0;
        iter = 0;
        numiters = nReps * nCond * nStimulusRepetitions;
        % stimulusrep applies when there are multiple stimuli for a particular
        % condition, e.g. different noise patterns.
        stimulusrep = 1;
        
        GetSecs;
        Screen('Screens');
        HideCursor;
        
        %%% Hand Mapping here
        if stim == 10
            DoHandMapping;
            doneStim = 1;
        elseif stim == 15 % white noise
            noisetype = 1;
            stx = 32;
            sty = 24;
            scale = 40;
            interval = 1;
            VBL_test = 1;
            num_textures = 600;
            frames_between_TTL = 50;
            destination_folder = './';
            scnum = str2double(get(handles.ScreenNum,'String'));
            stixel_num = 1;
            stixels_min_distance = 1;
            movie_file_name = '';
            
            if sync == kintan
                intanSyncData = [intanSyncData; [c ph s1(f)-startTime]];
                Noise_PSC(noisetype, stx, sty, scale, interval, VBL_test, num_textures,...
                    frames_between_TTL, destination_folder, scnum, stixel_num,...
                    stixels_min_distance, movie_file_name, serialhandle);
            end
            doneStim = 1;
        end
        %% loop on conditions
        while ~doneStim
            
%% here is where to put the condition for stimulus specificity test sspec
% iter = sspec_stim;

            %%% randomize conditions
            if get(handles.randomize,'Value');
                if mod(iter,nCond)==0   %%% shuffle condition list each rpeat
                    condList = Shuffle(1:nCond);
                end
            else
                condList = 1:nCond;
            end
            
            
           if get(handles.Var1,'Value') == 2
               disp('want stim output')
           end
            % choose condition for this iteration,
            c = condList(mod(iter,nCond)+1);
                       
            %% send condition out--must go before StimSync so that it is already there at beginning of stim
            if sync == ktdtSync
                putvalue(parentuddobj,c,condNum);
            elseif sync == ktdsUDP
                pnet(syncTDSUdp,'write',sprintf('B%c',c));
                pnet(syncTDSUdp,'writepacket',shutterHost,shutterPort);
            elseif sync == ktdtUDP
                % prepare string for sync
                if ~clut
                    tdtUDPstring = sprintf('%c%c',65, uint8(64*handles.eye(c)));
                else
                    if (c <= stimConds)
                        tdtUDPstring = sprintf('%d %d %d %d %0.2f %0.2f %0.2f',...
                            c,handles.var1value(c),handles.var2value(c),handles.var3value(c),get(handles.Var1,'Value'),get(handles.Var2,'Value'),get(handles.Var3,'Value'));
                    else
                        tdtUDPstring = sprintf('%d %d %d %d %0.2f %0.2f %0.2f',...
                            c,blankCond+flickCond,blankCond+flickCond,blankCond+flickCond,get(handles.Var1,'Value'),get(handles.Var2,'Value'),get(handles.Var3,'Value'));
                    end
                end
            elseif sync == ktdtPT
                lptwrite(888,0+0+(4*c));
            elseif sync == ktdtPTUDP
                lptwrite(888,0+0);
                if (c <= stimConds)
                    tdtUDPstring = sprintf('%d %d %d %d %0.2f %0.2f %0.2f',...
                        c,handles.var1value(c),handles.var2value(c),handles.var3value(c),get(handles.Var1,'Value'),get(handles.Var2,'Value'),get(handles.Var3,'Value'));
                else
                    tdtUDPstring = sprintf('%d %d %d %d %0.2f %0.2f %0.2f',...
                        c,blankCond+flickCond,blankCond+flickCond,blankCond+flickCond,get(handles.Var1,'Value'),get(handles.Var2,'Value'),get(handles.Var3,'Value'));
                end
                pnet(syncUdp,'write',tdtUDPstring);
                pnet(syncUdp,'writepacket',syncHost,syncPort);
                WaitSecs(0.001);
            elseif sync == kintan
               %stimsync conditional added MPS 2105Jan06
               if stimsync == 'LPT'
                %lptwrite(888,0); % < - commented out by MCD 2015
                lptwrite(888,1+0); % triggers recording in intan
               elseif stimsync == 'SER'
                IOPort('configureserialport', serialhandle, 'RTS=0'); % RTS=0 is 0V.
               else  %stimsync == 'UDP'
                pnet(stimsyncUdp, 'write', uint8(1+0));
                pnet(stimsyncUdp, 'writepacket', stimsynchost, stimsyncport);
               end
             
                if (c <= stimConds)
%                     tdtUDPstring = sprintf('%d %d %d %d %0.2f %0.2f %0.2f',...
%                         c,handles.var1value(c),handles.var2value(c),handles.var3value(c),get(handles.Var1,'Value'),get(handles.Var2,'Value'),get(handles.Var3,'Value'));
                tdtUDPstring = [c,handles.var1value(c),handles.var2value(c),handles.var3value(c),get(handles.Var1,'Value'),get(handles.Var2,'Value'),get(handles.Var3,'Value')];
                else
%                     tdtUDPstring = sprintf('%d %d %d %d %0.2f %0.2f %0.2f',...
%                         c,blankCond+flickCond,blankCond+flickCond,blankCond+flickCond,get(handles.Var1,'Value'),get(handles.Var2,'Value'),get(handles.Var3,'Value'));
% %                 c
%                 handles.var1value(c)
%                 handles.var2value(c)
%                 handles.var3value(c)
tdtUDPstring = [c,blankCond+flickCond,blankCond+flickCond,blankCond+flickCond,blankCond+flickCond,blankCond+flickCond,blankCond+flickCond];
                end
                pnet(syncUdp,'write',tdtUDPstring);
%                 sentnow = tdtUDPstring
%                 typeudp = class(sentnow)
%                 szupdstring = size(tdtUDPstring)
%                 thismeans = 'c,handles.var1value(c),handles.var2value(c),handles.var3value(c),get(handles.Var1,Value),get(handles.Var2,Value),get(handles.Var3,Value)'
                pnet(syncUdp,'writepacket',syncHost,syncPort);
                WaitSecs(0.001);
                %%% intanSyncData = [intanSyncData; [0 0 s1(f)-startTime]];
                
            end
            
            %% set eye shutters
            disp(sprintf('eye: %d',handles.eye(c)));
            eyeString = sprintf('%c%c',65, uint8(64*handles.eye(c)));
            pnet(shutterUdp,'write',eyeString);
            pnet(shutterUdp,'writepacket',shutterHost,shutterPort);
            
            
            %% raise the priority
            priorityLevel = MaxPriority(window);
            Priority(priorityLevel);
            clut
            
            minframe = 1; %default, unless stimgroups > 1
            maxframe = nFrames ;
            if clut  % lookup table animation
                clutcond = (squeeze(cluts(:,:,:,c)));
                %	first clut loaded is slow, so must load something
                %	(at least in old version)
                %   moglClutBlit(window,textures(c,1),currentclut);
                %   vbl = Screen('Flip',window);
            else  % movie
                %% set which frames to show
                if (stim == 3 && stimgroups > 1)
                    % if multiple condition movie, randomly choose a condition
                    offset = (c-1)*nStimulusRepetitions*phasePeriodFrames + ...
                        (stimulusrep-1)*phasePeriodFrames;
                    minframe = offset + 1;
                    maxframe = offset + phasePeriodFrames;
                end
            end
            if clut  %Stryker 2011-04-01 get rid of one-frame flash
                %moglClutBlit(window,textures(c),clutcond(:,:,1));
                moglClutBlit(window,textures(c),offclut);
            else
                vbl = Screen('Flip',window);  %%% initial flip, to sync with vertical blank
            end
            
            %% loop through frames
            f = minframe;
            while f <= maxframe
                s1(f) = GetSecs;
                if clut
                    moglClutBlit(window,textures(c),clutcond(:,:,f));
                    if get(handles.mask,'Value') == 1 && (get(handles.StimType,'Value')==1 || get(handles.StimType,'Value')==6)
                        Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                        baseRect = [0 0 800 600];
                        Screen('DrawTextures', window, maskTexture(c), [],baseRect, [], [], [], []);
                    end
                else % movie
                    Screen('DrawTexture',window, textures(texturec,f),[],destRect);
                end
                
                if f > 1
                    vbl = Screen('Flip',window, vbl + (FrameWait - 0.5) * FrameInt);
                else
                    vbl = Screen('Flip',window);
                end

                %% send pupil camera timestamp
                if ~mod(f-1,6)  % take pupil shot every 12 frames
                    tsnap = toc;
                    pnet(eyecamsock,'write',single(tsnap));
                    pnet(eyecamsock,'writepacket',eyecamhost,eyecamport);
                end
                %% Send StimSync and FrameSync
                if sync == kcsUDP
                    %ph = uint32(floor(phMax * mod(f-1,nFrames) /nFrames));
                    
                    % stryker/darcy 091312: calculate phase (ph) for movie
                    % or clut-based stimuli
                    if clut % lookup table animation
                        % to mimic ContImage
                        ph = uint32(floor(phMax * mod(f-1+(nFrames/2),nFrames) /nFrames));
                    else % movie
                        ph = uint32(floor(phMax * mod((f-1),phasePeriodFrames)/phasePeriodFrames));
                    end
                    
                    pnet(syncUdp,'write',[uint32(83 + 89*2^8) uint32(ph)],'intel');
                    pnet(syncUdp,'writepacket',syncHost,syncPort);
                    % pnet(syncUdp,'write',[uint32(83 + 89*2^8 +2^16)  uint32(handles.eye(c))],'intel');  %%% check this!
                    % pnet(syncUdp,'writepacket',syncHost,syncPort);
                elseif sync == ktdtSync
                    putvalue(parentuddobj,[bitOn bitOn],bitLine);
                    WaitSecs(0.001);
                    putvalue(parentuddobj,[bitOn bitOff],bitLine);
                elseif sync == ktdtUDP
                    pnet(syncUdp,'write',tdtUDPstring);
                    pnet(syncUdp,'writepacket',syncHost,syncPort);
                    WaitSecs(0.001); % 0.05
                elseif sync == ktdsUDP
                    pnet(syncTDSUdp,'write',sprintf('C%c',16+32));
                    pnet(syncTDSUdp,'writepacket',shutterHost,shutterPort);
                    WaitSecs(0.001);
                    pnet(syncTDSUdp,'write',sprintf('C%c',16+0));
                    pnet(syncTDSUdp,'writepacket',shutterHost,shutterPort);
                elseif sync == ktdtPT
                    lptwrite(888,1+2+(4*c));
                    WaitSecs(0.001);
                    lptwrite(888,1+0+(4*c));
                elseif sync == ktdtPTUDP
                    lptwrite(888,1+2);
                    WaitSecs(0.001);
                    lptwrite(888,1+0);
                elseif sync == kintan
                    %stimsync conditional added MPS 2105Jan06
                   if stimsync == 'LPT'
                    lptwrite(888,1+2); % 2^0 + 2^1 --- saying frame is on
                    WaitSecs(0.001);
                    lptwrite(888,1); % 2^0
                   elseif stimsync == 'SER'
                    IOPort('configureserialport', serialhandle, 'RTS=1'); % RTS=0 is 0V.
                   else  %stimsync == 'UDP'
                    pnet(stimsyncUdp, 'write', uint8(1+2));        %strobe framesync
                    pnet(stimsyncUdp, 'writepacket', stimsynchost, stimsyncport);
                    WaitSecs(0.0005);
                    pnet(stimsyncUdp, 'write', uint8(1+0));
                    pnet(stimsyncUdp, 'writepacket', stimsynchost, stimsyncport);
                   end
                     
%                     WaitSecs(0.001); % commented out by MCD 2015
%                     lptwrite(888,1+0); % commented out by MCD 2015
                    %                     IOPort('configureserialport', serialhandle, 'RTS=0'); % RTS=0 is 0V.
                    
                    if (stim == 3) % for correct sync, must be a movie
                        ph = (floor(phMax * mod(f-1,phasePeriodFrames) / phasePeriodFrames));
                    else
                        ph = f;
                    end
                    intanSyncData = [intanSyncData; [c ph s1(f)-startTime]];
                end
    %% real time stimulus change MPS 07/10/2016
                if runningexpt == 1
                    rsize=pnet(sockrunning,'readpacket',80,'noblock');
                    if rsize > 0
                        f = maxframe+1;
                        runstillcond = fix(pnet(sockrunning,'read',1,'int16','native'));
                       iter = runstillcond;
                     
                     %      iter = randi(4)
                    end
                end
     %  MPS 30Aug2016  Make sure to stop in mid-stimulus with ESC, 
     %  or else with number go to selected stimulus as in runningexpt
                simudpkey = simUDP();
                if simudpkey > 0
                    f = maxframe+1;
                    if simudpkey == 27
                        donestim = 1;
                        iter = numiters+1;
                    else  
                        iter = simudpkey;
                    end
                end
%%
                f = f+1;
            end
%% done with stimulus
            if clearBkgrnd
                if clut
                    %% Stryker
                    moglClutBlit(window,textures(c),offclut);
                else % movie
                    Screen('FillRect',window,grey);
                end
            else
                if clut
                    % darcy: another single frame flash bug?
                    % moglClutBlit(window,textures(c),clutcond(:,:,nFrames));
                    moglClutBlit(window,textures(c),offclut);
                    % currentclut = squeeze(clutcond(:,:,nFrames));
                end
            end
            vbl = Screen('Flip',window, vbl + (FrameWait - 0.5) * FrameInt);
            
            % Reset StimSynch
            if sync == ktdtSync
                putvalue(parentuddobj,[bitOff bitOff],bitLine);
            elseif sync == ktdsUDP
                pnet(syncTDSUdp,'write',sprintf('C%c',0+0));
                pnet(syncTDSUdp,'writepacket',shutterHost,shutterPort);
            elseif sync == ktdtPT
                lptwrite(888,0+0+(4*c));
            elseif sync == ktdtPTUDP
                lptwrite(888,0+0);
            elseif sync == kintan
                %stimsync conditional added MPS 2105Jan06
               if stimsync == 'LPT'
                lptwrite(888,1+0); % 2^0 + 2^1 --- saying frame is on
               elseif stimsync == 'SER'
                IOPort('configureserialport', serialhandle, 'RTS=0'); % RTS=0 is 0V.
               else  %stimsync == 'UDP'
                pnet(stimsyncUdp, 'write', uint8(0));
                pnet(stimsyncUdp, 'writepacket', stimsynchost, stimsyncport);
               end
                
%                 lptwrite(888,0+0); % mcd 2015
0                %save(syncfilename,'paramfilename','intanSyncData');
                % changed to unify intan file with parameter file
                save(paramfilename, 'paramfilename', 'intanSyncData', '-append');
                
            end
            
            Priority(0);
%            WaitSecs(WaitInt);
%  MPS 30Aug2016 Wait an integral number of frames instead of a fixed time, 
%  so that we get the pupil measurements during the wait period
%  Do not wait if runningexpt
        if ~runningexpt
            for ff=1:floor(WaitInt/FrameInt)
                vbl = Screen('Flip',window, vbl + (FrameWait - 0.5) * FrameInt);
    
                if ~mod(ff,6)  % take pupil shot every 6 fromes
                    tsnap = toc;
                    pnet(eyecamsock,'write',single(tsnap));
                    pnet(eyecamsock,'writepacket',eyecamhost,eyecamport);
                end
            end
        end
            
            if nFrames > 1
                ds = max(ds,diff(s1));
            end
            
            iter = iter + 1;
            
            elapsedTime = GetSecs - startTime;
            fprintf(statusfile,'%d %d %0.2f \r\n',iter,int16(numiters),elapsedTime);
            
            if mod(iter,nCond) == 0 %% done all conditions, move on to next stimulus
                stimulusrep = stimulusrep + 1;
                % if new Rep of entire movie, start new stimulusrep
                stimulusrep = mod(stimulusrep-1,nStimulusRepetitions)+1;
            end
            
            % look for stop message ESCAPE on keyboard
            % use kbname on a mac to see if this is correct for the mac
            [keyIsDown, secs, keyCode] = KbCheck;
            if keyIsDown %%% charavail would be much better, but doesn't seem to work
                key = find(keyCode);
                if key == 27
                    doneStim = 1;
                    disp('Exit on a ESC');
                end
%                 keyspressed = KbName(find(keyCode));
%                 %disp(sprintf('Exit on %s key pressed',keyspressed{1})); %
%                 %somehow giving an error
%                 disp('Exit on a keypress');
            end
            
            % look for stop message on UDP
            if pnet(stopudp,'readpacket',20,'noblock') > 0
                msg = pnet(stopudp,'read','char')
                if strcmp(msg,'stop')
                    doneStim = 1;
                    disp('Exit on UDP');
                end
            end
            
            % test for all stimuli complete
            if (iter >= numiters)
                doneStim = 1;
                disp('Exit on completion');
            end
            
        end %while ~doneStim
        pnet(eyecamsock,'write',single(-1));
        pnet(eyecamsock,'writepacket',eyecamhost,eyecamport);

        if sync == ktdtUDP   %% write one last packet to end last trial
            pnet(syncUdp,'write',sprintf('%d %d %d %0.2f %0.2f',999,999,999,0.0,0.0));
            pnet(syncUdp,'writepacket',syncHost,syncPort);
        end
        if sync == kintan
           %stimsync conditional added MPS 2105Jan06
           if stimsync == 'LPT'
            lptwrite(888,0); % 2^0 + 2^1 --- saying frame is on
           elseif stimsync == 'SER'
            IOPort('configureserialport', serialhandle, 'RTS=0'); % RTS=0 is 0V.
           else  %stimsync == 'UDP'
            pnet(stimsyncUdp, 'write', uint8(0));
            pnet(stimsyncUdp, 'writepacket', stimsynchost, stimsyncport);
            pnet(stimsyncUdp,'close');
           end
            pnet(trackballsocket,'write',sprintf('%s\n', 'close'));
            pnet(trackballsocket,'writepacket', trackballhost, trackballport);
            pnet(trackballsocket,'close');
            pnet(syncUdp,'close');
        end
        
        
        Priority(0);
        
        %%%% cleanup   %%%%
        moglClutBlit;
        if sync == ktdtUDP
            pnet(syncUdp,'close');
        end
        pnet(shutterUdp,'close');
        ListenChar(1);
        pnet('closeall')
        fclose(statusfile);
        Screen('LoadNormalizedGammaTable',window,flat_clut);
        Screen('CloseAll');
        
        f = figure(1);
        set(f,'Position',[1 35 1024 130])
        plot(ds);
        title('Dropped frames');
        
        ShowCursor;
        %%% if there's an error, clean up and rethrow the error
    catch
        ShowCursor;
        pnet('closeall')
        fclose(statusfile)
        ListenChar(1);
        Screen('LoadNormalizedGammaTable',window,flat_clut);
        if clut
            moglClutBlit;  %%%% need to close this, or won't work next time
        end
        Screen('CloseAll');
        
        Priority(0);
        psychrethrow(psychlasterror);
    end
    
    kcsUDP
catch e
    sca
    rethrow(e)
end


% --- Executes on button press in SaveParams.
function SaveParams_Callback(hObject, eventdata, handles) %#ok
% hObject    handle to SaveParams (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global paramdirpath;

[fname, pname] = uiputfile('*.mat','Parameter File',paramdirpath);
if (fname == 0), return; end % canceled

fname = fullfile(pname,fname);
SaveParams(handles,fname);

paramdirpath = pname;

%--- function to save parameters, called by SaveParams, or on Run_Btn
function SaveParams(handles,fname)

Orient0 = str2double(get(handles.Orient0,'String')); %#ok
Freq0 = str2double(get(handles.Freq0,'String')); %#ok
Speed0 = str2double(get(handles.Speed0,'String')); %#ok
Contrast0 = str2double(get(handles.Contrast0,'String')); %#ok
TempFreq0 = str2double(get(handles.TempFreq0,'String')); %#ok
Duration= str2double(get(handles.Duration,'String')); %#ok
Phase0 = str2double(get(handles.Phase0,'String')); %#ok
Length0 = str2double(get(handles.Length0,'String')); %#ok
PositionX0 = str2double(get(handles.PositionX0,'String')); %#ok
PositionY0 = str2double(get(handles.PositionY0,'String')); %#ok
WaitInterval = str2double(get(handles.WaitInterval,'String')); %#ok
eyeCond0 = str2double(get(handles.eyeCond0,'String'));

StimulusStr = get(handles.StimType,'String'); %#ok
StimulusNum = get(handles.StimType,'Value'); %#ok

PixelsX = str2double(get(handles.PixelsX,'String')); %#ok
PixelsY = str2double(get(handles.PixelsY,'String')); %#ok
SizeX = str2double(get(handles.SizeX,'String')); %#ok
SizeY = str2double(get(handles.SizeY,'String')); %#ok
ScreenDist = str2double(get(handles.ScreenDist,'String')); %#ok

Var1Str = get(handles.Var1,'String'); %#ok
Var1Val = get(handles.Var1,'Value'); %#ok

Start1 = str2double(get(handles.Start1,'String')); %#ok
Stop1 = str2double(get(handles.Stop1,'String')); %#ok
nSteps1 = str2double(get(handles.nSteps1,'String')); %#ok
LinLog1 = get(handles.LinLog1,'Value'); %#ok


Var2Str = get(handles.Var2,'String'); %#ok
Var2Val = get(handles.Var2,'Value'); %#ok

Start2 = str2double(get(handles.Start2,'String')); %#ok
Stop2 = str2double(get(handles.Stop2,'String')); %#ok
nSteps2 = str2double(get(handles.nSteps2,'String')); %#ok
LinLog2 = get(handles.LinLog2,'Value'); %#ok

Var3Str = get(handles.Var3,'String'); %#ok
Var3Val = get(handles.Var3,'Value'); %#ok

Start3 = str2double(get(handles.Start3,'String')); %#ok
Stop3 = str2double(get(handles.Stop3,'String')); %#ok
nSteps3 = str2double(get(handles.nSteps3,'String')); %#ok
LinLog3 = get(handles.LinLog3,'Value'); %#ok

MovieName = get(handles.MovieName,'String'); %#ok
MovieMag = str2double(get(handles.MovieMag,'String')); %#ok
MovieRate = str2double(get(handles.MovieRate,'String')); %#ok
phasePeriod = str2double(get(handles.phasePeriod,'String')); %#ok
stimulusGroups = str2double(get(handles.stimulusGroups,'String')); %#ok

SyncSource = get(handles.SyncSource,'Value'); %#ok

blankbkgrnd = get(handles.bkgrnd,'Value'); %#ok
randomize = get(handles.randomize,'Value'); %#ok
blankstim = get(handles.blankstim,'Value'); %#ok
FullFlicker = get(handles.FullFlicker,'Value'); %#ok
nReps = get(handles.nReps,'String'); %#ok

orient = handles.orient; %#ok
freq = handles.freq; %#ok
speed = handles.speed; %#ok
contrast = handles.contrast; %#ok
phase = handles.phase; %#ok
TempFreq = handles.TempFreq; %#ok
positionX = handles.positionX; %#ok
positionY = handles.positionY; %#ok
length = handles.length; %#ok
squaregratings = get(handles.squaregratings,'Value'); %#ok

DoNearScreen = get(handles.DoNearScreen,'Value');
cp_azdeg = str2double(get(handles.cp_azdeg,'String'));
cp_eldeg = str2double(get(handles.cp_eldeg,'String'));
cpx_cm = str2double(get(handles.cpx_cm,'String'));
cpy_cm = str2double(get(handles.cpy_cm,'String'));
backlum = str2double(get(handles.BackLum,'String'));
mask_on = get(handles.mask,'Value');

% darcy 30107: added missing SyncSource var to list of saved params
save(fname, 'Orient0', 'Freq0', 'TempFreq0','Phase0','Speed0', 'Contrast0','Duration','Length0','PositionX0', 'PositionY0', 'WaitInterval','eyeCond0','StimulusStr', 'StimulusNum', ...
    'PixelsX','PixelsY','SizeX','SizeY','ScreenDist','Var1Str','Var1Val','Start1','Stop1','nSteps1','LinLog1', ...
    'Var2Str','Var2Val','Start2','Stop2','nSteps2','LinLog2','Var3Str','Var3Val','Start3','Stop3','nSteps3','LinLog3', ...
    'MovieName','MovieMag','MovieRate', ...
    'orient', 'freq', 'speed', 'contrast','phase','TempFreq','length','positionX','positionY','blankbkgrnd','randomize','blankstim','FullFlicker',...
    'nReps','phasePeriod','stimulusGroups','squaregratings', ...
    'DoNearScreen', 'cp_azdeg', 'cp_eldeg', 'cpx_cm', 'cpy_cm','backlum', ...
    'SyncSource');

% --- Executes on button press in LoadParams.
function LoadParams_Callback(hObject, eventdata, handles) %#ok
% hObject    handle to LoadParams (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global paramdirpath;

[fname, pname] = uigetfile('*.mat','Parameter File',paramdirpath);
if (fname == 0), return; end % canceled

load(fullfile(pname,fname));
paramdirpath = pname;

set(handles.StimType,'Value',StimulusNum);
set(handles.Orient0,'String',num2str(Orient0));
set(handles.Freq0,'String',num2str(Freq0));
set(handles.Speed0,'String',num2str(Speed0));
set(handles.Contrast0,'String',num2str(Contrast0));
set(handles.Duration,'String',num2str(Duration));

set(handles.PixelsX,'String',num2str(PixelsX));
set(handles.PixelsY,'String',num2str(PixelsY));
set(handles.SizeX,'String',num2str(SizeX));
set(handles.SizeY,'String',num2str(SizeY));
set(handles.ScreenDist,'String',num2str(ScreenDist));

set(handles.Var1,'Value',Var1Val);
set(handles.Start1,'String',num2str(Start1));
set(handles.Stop1,'String',num2str(Stop1));
set(handles.nSteps1,'String',num2str(nSteps1));
set(handles.LinLog1,'Value',LinLog1);

set(handles.Var2,'Value',Var2Val);
set(handles.Start2,'String',num2str(Start2));
set(handles.Stop2,'String',num2str(Stop2));
set(handles.nSteps2,'String',num2str(nSteps2));
set(handles.LinLog2,'Value',LinLog2);

set(handles.Var3,'Value',Var3Val);
set(handles.Start3,'String',num2str(Start3));
set(handles.Stop3,'String',num2str(Stop3));
set(handles.nSteps3,'String',num2str(nSteps3));
set(handles.LinLog3,'Value',LinLog3);

set(handles.MovieName,'String',MovieName);
set(handles.MovieMag,'String',num2str(MovieMag));
set(handles.MovieRate,'String',num2str(MovieRate));
set(handles.WaitInterval,'String',num2str(WaitInterval));

if exist('TempFreq0','var')   %added 28Mar2006
    set(handles.TempFreq0,'String',num2str(TempFreq0));
    set(handles.Phase0,'String',num2str(Phase0));
end

if exist('Length0','var')  %% added 20Jul2006
    set(handles.randomize,'Value',randomize);
    set(handles.blankstim,'Value',blankstim);
    set(handles.bkgrnd,'Value',blankbkgrnd);
    set(handles.Length0,'String',num2str(Length0));
    %  set(handles.PositionX0,'String',num2str(Position0));
    set(handles.WaitInterval,'String',num2str(WaitInterval));
end

if exist('PositionY0','var') %%% added 18Aug2006
    set(handles.PositionX0,'String',num2str(PositionX0));
    set(handles.PositionY0,'String',num2str(PositionY0));
end

if exist('FullFlicker','var') %%% added Jan172007
    set(handles.FullFlicker,'Value',FullFlicker);
end

if exist('nReps','var') %%% added 15Aug2007
    set(handles.nReps,'String',num2str(nReps));
    set(handles.phasePeriod,'String',num2str(phasePeriod));
    set(handles.stimulusGroups,'String',num2str(stimulusGroups));
end

if exist('squaregratings','var') %%% added 27Sep2007
    set(handles.squaregratings,'Value',squaregratings);
end

if exist('eyeCond0','var') %%% added 10Oct2007
    set(handles.eyeCond0,'String',num2str(eyeCond0));
end

if exist('SyncSource','var') %%% added 20Oct2007
    set(handles.SyncSource,'Value',SyncSource);
end

if exist('DoNearScreen','var') %%% Stryker added 1May2011
    set(handles.DoNearScreen,'Value',DoNearScreen);
    set(handles.cp_azdeg,'String',num2str(cp_azdeg));
    set(handles.cp_eldeg,'String',num2str(cp_eldeg));
    set(handles.cpx_cm,'String',num2str(cpx_cm));
    set(handles.cpy_cm,'String',num2str(cpy_cm));
end

if exist('backlum','var')
    set(handles.BackLum,'String',num2str(backlum));
end

StimType_Callback(handles.StimType,eventdata,handles);
Var1_Callback(handles.Var1,eventdata,handles);
Var2_Callback(handles.Var2,eventdata,handles);
Var3_Callback(handles.Var3,eventdata,handles);

% --- Executes on button press in WaitSync.
function WaitSync_Callback(hObject, eventdata, handles) %#ok



function TempFreq0_Callback(hObject, eventdata, handles) %#ok
StimType_Callback(handles.StimType,eventdata,handles);

% --- Executes during object creation, after setting all properties.
function TempFreq0_CreateFcn(hObject, eventdata, handles) %#ok
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Phase0_Callback(hObject, eventdata, handles) %#ok
StimType_Callback(handles.StimType,eventdata,handles);

% --- Executes during object creation, after setting all properties.
function Phase0_CreateFcn(hObject, eventdata, handles) %#ok
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Orient0_Callback(hObject, eventdata, handles) %#ok
StimType_Callback(handles.StimType,eventdata,handles);

% --- Executes during object creation, after setting all properties.
function Orient0_CreateFcn(hObject, eventdata, handles) %#ok
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Freq0_Callback(hObject, eventdata, handles) %#ok
StimType_Callback(handles.StimType,eventdata,handles);

% --- Executes during object creation, after setting all properties.
function Freq0_CreateFcn(hObject, eventdata, handles) %#ok
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Speed0_Callback(hObject, eventdata, handles) %#ok
StimType_Callback(handles.StimType,eventdata,handles);

% --- Executes during object creation, after setting all properties.
function Speed0_CreateFcn(hObject, eventdata, handles) %#ok
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Contrast0_Callback(hObject, eventdata, handles) %#ok
StimType_Callback(handles.StimType,eventdata,handles);

% --- Executes during object creation, after setting all properties.
function Contrast0_CreateFcn(hObject, eventdata, handles) %#ok
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Duration_Callback(hObject, eventdata, handles) %#ok

function Duration_CreateFcn(hObject, eventdata, handles) %#ok
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



% --- Executes on selection change in Var1.
function Var1_Callback(hObject, eventdata, handles)
% hObject    handle to Var1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns Var1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Var1

if get(hObject,'Value')==1 %none
    set(handles.Start1,'Enable','off');
    set(handles.Stop1,'Enable','off');
    set(handles.nSteps1,'Enable','off');
    set(handles.LinLog1,'Enable','off');
    set(handles.Var1Range,'Enable','off');
else
    set(handles.Start1,'Enable','on');
    set(handles.Stop1,'Enable','on');
    set(handles.nSteps1,'Enable','on');
    set(handles.LinLog1,'Enable','on');
    set(handles.Var1Range,'Enable','on');
end

Var1Range_Callback(handles.Var1Range,eventdata,handles);


% --- Executes during object creation, after setting all properties.
function Var1_CreateFcn(hObject, eventdata, handles) %#ok
% hObject    handle to Var1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


% --- Executes on selection change in Var2.
function Var2_Callback(hObject, eventdata, handles)
% hObject    handle to Var2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns Var2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Var2

if get(hObject,'Value')==1 %none
    set(handles.Start2,'Enable','off');
    set(handles.Stop2,'Enable','off');
    set(handles.nSteps2,'Enable','off');
    set(handles.LinLog2,'Enable','off');
    set(handles.Var2Range,'Enable','off');
    
else
    set(handles.Start2,'Enable','on');
    set(handles.Stop2,'Enable','on');
    set(handles.nSteps2,'Enable','on');
    set(handles.LinLog2,'Enable','on');
    set(handles.Var2Range,'Enable','on');
end

Var2Range_Callback(handles.Var2Range,eventdata,handles);

% --- Executes during object creation, after setting all properties.
function Var2_CreateFcn(hObject, eventdata, handles) %#ok
% hObject    handle to Var2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


% --- Executes on selection change in LinLog1.
function LinLog1_Callback(hObject, eventdata, handles) %#ok
Var1_Callback(handles.Var1, eventdata, handles);

% --- Executes during object creation, after setting all properties.
function LinLog1_CreateFcn(hObject, eventdata, handles) %#ok
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Start1_Callback(hObject, eventdata, handles) %#ok

Var1_Callback(handles.Var1, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function Start1_CreateFcn(hObject, eventdata, handles) %#ok
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Stop1_Callback(hObject, eventdata, handles) %#ok
Var1_Callback(handles.Var1, eventdata, handles);

% --- Executes during object creation, after setting all properties.
function Stop1_CreateFcn(hObject, eventdata, handles) %#ok
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function nSteps1_Callback(hObject, eventdata, handles) %#ok
Var1_Callback(handles.Var1, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function nSteps1_CreateFcn(hObject, eventdata, handles) %#ok
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Start2_Callback(hObject, eventdata, handles) %#ok
Var2_Callback(handles.Var2, eventdata, handles);

% --- Executes during object creation, after setting all properties.
function Start2_CreateFcn(hObject, eventdata, handles) %#ok
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Stop2_Callback(hObject, eventdata, handles) %#ok
Var2_Callback(handles.Var2, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function Stop2_CreateFcn(hObject, eventdata, handles) %#ok
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function nSteps2_Callback(hObject, eventdata, handles) %#ok
Var2_Callback(handles.Var2, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function nSteps2_CreateFcn(hObject, eventdata, handles) %#ok
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


% --- Executes on selection change in LinLog2.
function LinLog2_Callback(hObject, eventdata, handles) %#ok
Var2_Callback(handles.Var2, eventdata, handles);

% --- Executes during object creation, after setting all properties.
function LinLog2_CreateFcn(hObject, eventdata, handles) %#ok
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


function Var1Range_Callback(hObject, eventdata, handles) %#ok

nSteps1 = str2double(get(handles.nSteps1,'String'));
Start1 = str2double(get(handles.Start1,'String'));
Stop1 = str2double(get(handles.Stop1,'String'));
LinLog1 = get(handles.LinLog1,'Value');

variscircular = 0;
if (get(handles.Var1,'Value')) == 2 && (Start1 == 0) && (Stop1 == 360)
    variscircular = 1; % orientation
end

if LinLog1 == 1
    if variscircular
        Var1Range = linspace(Start1, Stop1, nSteps1+1);
        Var1Range = Var1Range(1:end-1);
    else
        Var1Range = linspace(Start1, Stop1, nSteps1);
    end
elseif LinLog1 == 2
    Var1Range = logspace(log10(Start1), log10(Stop1), nSteps1);
else
    Var1Range = str2num(get(handles.Var1Range,'String'));
    % could set nSteps to correct value at this poitn, but no real need
end
set(hObject,'String',mat2str(Var1Range,3));

[handles.orient handles.freq handles.speed handles.contrast handles.phase ...
    handles.TempFreq handles.var1value handles.var2value handles.var3value ...
    handles.positionX handles.positionY handles.length handles.eye] = generateVarParams(handles);

%% Cris had an arbitrary coding scheme--why?  Constim compatibility?
codes = [0 4 23 10 13 24 18 7 8  22, 999]; % Shinya added 999 for adding length, without knowing what this coding is.
handles.var1code = codes(get(handles.Var1,'Value'));
handles.var2code = codes(get(handles.Var2,'Value'));

guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function Var1Range_CreateFcn(hObject, eventdata, handles) %#ok
% hObject    handle to Var1Range (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


function Var2Range_Callback(hObject, eventdata, handles) %#ok
% hObject    handle to Var2Range (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Var2Range as text
%        str2double(get(hObject,'String')) returns contents of Var2Range as a double

nSteps2 = str2double(get(handles.nSteps2,'String'));
Start2 = str2double(get(handles.Start2,'String'));
Stop2 = str2double(get(handles.Stop2,'String'));
LinLog2 = get(handles.LinLog2,'Value');

variscircular = 0;
if (get(handles.Var2,'Value')) == 2 && (Start2 == 0) && (Stop2 == 360)
    variscircular = 1; % orientation
end

if LinLog2 == 1
    if variscircular
        Var2Range = linspace(Start2, Stop2, nSteps2+1);
        Var2Range = Var2Range(1:end-1);
    else
        Var2Range = linspace(Start2, Stop2, nSteps2);
    end
elseif LinLog2 == 2
    Var2Range = logspace(log10(Start2), log10(Stop2), nSteps2);
else
    Var2Range = str2num(get(handles.Var2Range,'String'));
end
set(hObject,'String',mat2str(Var2Range,3));

[handles.orient handles.freq handles.speed handles.contrast handles.phase ...
    handles.TempFreq handles.var1value handles.var2value handles.var3value ...
    handles.positionX handles.positionY handles.length handles.eye] = generateVarParams(handles);

%% Cris had an arbitrary coding scheme--why?  Constim compatibility?
%codes = [0 4 23 10 13 24 18 7 8  22];
codes = [0 4 23 10 13 24 18 7 8  22, 999]; % Shinya added 999 for adding length, without knowing what this coding is.

handles.var1code =codes(get(handles.Var1,'Value'));
handles.var2code =codes(get(handles.Var2,'Value'));
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function Var2Range_CreateFcn(hObject, eventdata, handles) %#ok
% hObject    handle to Var2Range (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.

if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

function MovieName_Callback(hObject, eventdata, handles) %#ok
% hObject    handle to MovieName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MovieName as text
%        str2double(get(hObject,'String')) returns contents of MovieName as a double

updateparamsfrommovie(get(hObject,'String'),handles);

% --- Executes during object creation, after setting all properties.
function MovieName_CreateFcn(hObject, eventdata, handles) %#ok
% hObject    handle to MovieName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


% --- Executes on button press in SelectMovieName.
function SelectMovieName_Callback(hObject, eventdata, handles) %#ok
% hObject    handle to SelectMovieName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global moviedirpath;

[fname pname] = uigetfile('.mat','Movie Name',moviedirpath);
if (fname == 0); return; end

fullmoviename = fullfile(pname,fname);
moviedirpath = pname;

set(handles.MovieName,'String',fullmoviename);

updateparamsfrommovie(fullmoviename,handles);


function MovieMag_Callback(hObject, eventdata, handles) %#ok
% hObject    handle to MovieMag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MovieMag as text
%        str2double(get(hObject,'String')) returns contents of MovieMag as a double


% --- Executes during object creation, after setting all properties.
function MovieMag_CreateFcn(hObject, eventdata, handles) %#ok
% hObject    handle to MovieMag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


% --- Executes on selection change in SyncSource.
function SyncSource_Callback(hObject, eventdata, handles) %#ok
% hObject    handle to SyncSource (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns SyncSource contents as cell array
%        contents{get(hObject,'Value')} returns selected item from SyncSource

% --- Executes during object creation, after setting all properties.
function SyncSource_CreateFcn(hObject, eventdata, handles) %#ok
% hObject    handle to SyncSource (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


function WaitInterval_Callback(hObject, eventdata, handles) %#ok
% hObject    handle to WaitInterval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of WaitInterval as text
%        str2double(get(hObject,'String')) returns contents of WaitInterval as a double


% --- Executes during object creation, after setting all properties.
function WaitInterval_CreateFcn(hObject, eventdata, handles) %#ok
% hObject    handle to WaitInterval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


function ScreenNum_Callback(hObject, eventdata, handles) %#ok
% hObject    handle to ScreenNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ScreenNum as text
%        str2double(get(hObject,'String')) returns contents of ScreenNum as a double
FrameHz_Callback(handles.FrameHz,eventdata,handles);
PixelsX_Callback(handles.PixelsX,eventdata,handles);
PixelsY_Callback(handles.PixelsY,eventdata,handles);



% --- Executes during object creation, after setting all properties.
function ScreenNum_CreateFcn(hObject, eventdata, handles) %#ok
% hObject    handle to ScreenNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end




function PixelsX_Callback(hObject, eventdata, handles) %#ok
% hObject    handle to PixelsX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of PixelsX as text
%        str2double(get(hObject,'String')) returns contents of PixelsX as a double
screenNum = str2double(get(handles.ScreenNum,'String'));
rect = Screen(screenNum,'Rect');
set(hObject,'String',num2str(rect(3)));


% --- Executes during object creation, after setting all properties.
function PixelsX_CreateFcn(hObject, eventdata, handles) %#ok
% hObject    handle to PixelsX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function PixelsY_Callback(hObject, eventdata, handles) %#ok
% hObject    handle to PixelsY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of PixelsY as text
%        str2double(get(hObject,'String')) returns contents of PixelsY as a double
screenNum = str2double(get(handles.ScreenNum,'String'));
rect = Screen(screenNum,'Rect');
set(hObject,'String',num2str(rect(4)));

% --- Executes during object creation, after setting all properties.
function PixelsY_CreateFcn(hObject, eventdata, handles) %#ok
% hObject    handle to PixelsY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function SizeX_Callback(hObject, eventdata, handles) %#ok
% hObject    handle to SizeX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SizeX as text
%        str2double(get(hObject,'String')) returns contents of SizeX as a double


% --- Executes during object creation, after setting all properties.
function SizeX_CreateFcn(hObject, eventdata, handles) %#ok
% hObject    handle to SizeX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function SizeY_Callback(hObject, eventdata, handles) %#ok
% hObject    handle to SizeY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SizeY as text
%        str2double(get(hObject,'String')) returns contents of SizeY as a double


% --- Executes during object creation, after setting all properties.
function SizeY_CreateFcn(hObject, eventdata, handles) %#ok
% hObject    handle to SizeY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function ScreenDist_Callback(hObject, eventdata, handles) %#ok
% hObject    handle to ScreenDist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ScreenDist as text
%        str2double(get(hObject,'String')) returns contents of ScreenDist as a double


% --- Executes during object creation, after setting all properties.
function ScreenDist_CreateFcn(hObject, eventdata, handles) %#ok
% hObject    handle to ScreenDist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

function FrameHz_Callback(hObject, eventdata, handles) %#ok
% hObject    handle to FrameHz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of FrameHz as text
%        str2double(get(hObject,'String')) returns contents of FrameHz as a double
set(hObject,'String',num2str(FrameRate(str2double(get(handles.ScreenNum,'String')))));


% --- Executes during object creation, after setting all properties.
function FrameHz_CreateFcn(hObject, eventdata, handles) %#ok
% hObject    handle to FrameHz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


function MovieRate_Callback(hObject, eventdata, handles) %#ok
% hObject    handle to MovieRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MovieRate as text
%        str2double(get(hObject,'String')) returns contents of MovieRate as a double


% --- Executes during object creation, after setting all properties.
function MovieRate_CreateFcn(hObject, eventdata, handles) %#ok
% hObject    handle to MovieRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


% --- Executes on button press in bkgrnd.
function bkgrnd_Callback(hObject, eventdata, handles) %#ok
% hObject    handle to bkgrnd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of bkgrnd


% --- Executes on button press in randomize.
function randomize_Callback(hObject, eventdata, handles) %#ok
% hObject    handle to randomize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of randomize


function Length0_Callback(hObject, eventdata, handles) %#ok
StimType_Callback(handles.StimType,eventdata,handles);

% --- Executes during object creation, after setting all properties.
function Length0_CreateFcn(hObject, eventdata, handles) %#ok
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function PositionX0_Callback(hObject, eventdata, handles) %#ok
% a = get(hObject,'String'); % added MCD 150226
% set(hObject,'Value',str2num(a));% added MCD 150226
StimType_Callback(handles.StimType,eventdata,handles);


% --- Executes during object creation, after setting all properties.
function PositionX0_CreateFcn(hObject, eventdata, handles) %#ok

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in blankstim.
function blankstim_Callback(hObject, eventdata, handles) %#ok
% hObject    handle to blankstim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of blankstim


function PositionY0_Callback(hObject, eventdata, handles) %#ok
% b = get(hObject,'String'); % added MCD 150226
% set(hObject,'Value',str2num(b));% added MCD 150226
StimType_Callback(handles.StimType,eventdata,handles);

% --- Executes during object creation, after setting all properties.
function PositionY0_CreateFcn(hObject, eventdata, handles) %#ok
% hObject    handle to PositionY0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes on button press in FullFlicker.
function FullFlicker_Callback(hObject, eventdata, handles) %#ok
% hObject    handle to FullFlicker (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of FullFlicker


function phasePeriod_Callback(hObject, eventdata, handles) %#ok
% hObject    handle to phasePeriod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of phasePeriod as text
%        str2double(get(hObject,'String')) returns contents of phasePeriod as a double


% --- Executes during object creation, after setting all properties.
function phasePeriod_CreateFcn(hObject, eventdata, handles) %#ok
% hObject    handle to phasePeriod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function nReps_Callback(hObject, eventdata, handles) %#ok
% hObject    handle to nReps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of nReps as text
%        str2double(get(hObject,'String')) returns contents of nReps as a double


% --- Executes during object creation, after setting all properties.
function nReps_CreateFcn(hObject, eventdata, handles) %#ok
% hObject    handle to nReps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function stimulusGroups_Callback(hObject, eventdata, handles) %#ok
% hObject    handle to stimulusGroups (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of stimulusGroups as text
%        str2double(get(hObject,'String')) returns contents of stimulusGroups as a double

% --- Executes during object creation, after setting all properties.
function stimulusGroups_CreateFcn(hObject, eventdata, handles) %#ok
% hObject    handle to stimulusGroups (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in squaregratings.
function squaregratings_Callback(hObject, eventdata, handles) %#ok
% hObject    handle to squaregratings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of squaregratings


function updateparamsfrommovie(fullmoviename,handles)

% update variables after select
load(fullmoviename,'MovieMag','MovieRate','period_sec');

if exist('MovieMag','var')
    % movie meta-data variables saved:
    %  'duration_sec','period_sec','MovieMag','MovieRate','screenDistanceCm'
    
    set(handles.MovieMag,'String',num2str(MovieMag)); %#ok
    set(handles.MovieRate,'String',num2str(MovieRate)); %#ok
    set(handles.phasePeriod,'String',num2str(period_sec)); %#ok
    
    % other variables that could be saved:
    % duration_sec (default is to play whole movie)
    % screenDistanceCm (irrelevant for movies)
    % xsize (no ysize)
end



% --- Executes on button press in eyeCond0.
function eyeCond0_Callback(hObject, eventdata, handles)
% hObject    handle to eyeCond0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function eyeCond0_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eyeCond0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called



% --- Executes on selection change in Var3.
function Var3_Callback(hObject, eventdata, handles)
% hObject    handle to Var3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns Var3 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Var3

if get(hObject,'Value')==1 %none
    set(handles.Start3,'Enable','off');
    set(handles.Stop3,'Enable','off');
    set(handles.nSteps3,'Enable','off');
    set(handles.LinLog3,'Enable','off');
    set(handles.Var3Range,'Enable','off');
    
else
    set(handles.Start3,'Enable','on');
    set(handles.Stop3,'Enable','on');
    set(handles.nSteps3,'Enable','on');
    set(handles.LinLog3,'Enable','on');
    set(handles.Var3Range,'Enable','on');
end
Var3Range_Callback(handles.Var3Range,eventdata,handles);

% --- Executes during object creation, after setting all properties.
function Var3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Var3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Start3_Callback(hObject, eventdata, handles)
% hObject    handle to Start3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Start3 as text
%        str2double(get(hObject,'String')) returns contents of Start3 as a double
Var3_Callback(handles.Var3, eventdata, handles);

% --- Executes during object creation, after setting all properties.
function Start3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Start3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Stop3_Callback(hObject, eventdata, handles)
% hObject    handle to Stop3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Stop3 as text
%        str2double(get(hObject,'String')) returns contents of Stop3 as a double
Var3_Callback(handles.Var3, eventdata, handles);

% --- Executes during object creation, after setting all properties.
function Stop3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Stop3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function nSteps3_Callback(hObject, eventdata, handles)
% hObject    handle to nSteps3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of nSteps3 as text
%        str2double(get(hObject,'String')) returns contents of nSteps3 as a double
Var3_Callback(handles.Var3, eventdata, handles);

% --- Executes during object creation, after setting all properties.
function nSteps3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to nSteps3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


% --- Executes on selection change in LinLog3.
function LinLog3_Callback(hObject, eventdata, handles)
% hObject    handle to LinLog3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns LinLog3 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from LinLog3
Var3_Callback(handles.Var3, eventdata, handles);

% --- Executes during object creation, after setting all properties.
function LinLog3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LinLog3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Var3Range_Callback(hObject, eventdata, handles)
% hObject    handle to Var3Range (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Var3Range as text
%        str2double(get(hObject,'String')) returns contents of Var3Range as a double
nSteps3 = str2double(get(handles.nSteps3,'String'));
Start3 = str2double(get(handles.Start3,'String'));
Stop3 = str2double(get(handles.Stop3,'String'));
LinLog3 = get(handles.LinLog3,'Value');

variscircular = 0;
if (get(handles.Var3,'Value')) == 2 && (Start3 == 0) && (Stop3 == 360)
    variscircular = 1; % orientation
end

if LinLog3 == 1
    if variscircular
        Var3Range = linspace(Start3, Stop3, nSteps3+1);
        Var3Range = Var3Range(1:end-1);
    else
        Var3Range = linspace(Start3, Stop3, nSteps3);
    end
elseif LinLog3 == 2
    Var3Range = logspace(log10(Start3), log10(Stop3), nSteps3);
else
    Var3Range = str2num(get(handles.Var3Range,'String'));
end
set(hObject,'String',mat2str(Var3Range,3));

[handles.orient handles.freq handles.speed handles.contrast handles.phase ...
    handles.TempFreq handles.var1value handles.var2value handles.var3value ...
    handles.positionX handles.positionY handles.length handles.eye] = generateVarParams(handles);

%% Cris had an arbitrary coding scheme--why?  Constim compatibility?
%codes = [0 4 23 10 13 24 18 7 8  22];
codes = [0 4 23 10 13 24 18 7 8  22, 999]; % Shinya added 999 for adding length, without knowing what this coding is.

handles.var1code =codes(get(handles.Var1,'Value'));
handles.var2code =codes(get(handles.Var2,'Value'));
handles.var3code =codes(get(handles.Var3,'Value'));
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function Var3Range_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Var3Range (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end





function cp_azdeg_Callback(hObject, eventdata, handles)
% hObject    handle to cp_azdeg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cp_azdeg as text
%        str2double(get(hObject,'String')) returns contents of cp_azdeg as a double


% --- Executes during object creation, after setting all properties.
function cp_azdeg_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cp_azdeg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function cp_eldeg_Callback(hObject, eventdata, handles)
% hObject    handle to cp_eldeg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cp_eldeg as text
%        str2double(get(hObject,'String')) returns contents of cp_eldeg as a double


% --- Executes during object creation, after setting all properties.
function cp_eldeg_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cp_eldeg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in DoNearScreen.
function DoNearScreen_Callback(hObject, eventdata, handles)
% hObject    handle to DoNearScreen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of DoNearScreen



function cpx_cm_Callback(hObject, eventdata, handles)
% hObject    handle to cpx_cm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cpx_cm as text
%        str2double(get(hObject,'String')) returns contents of cpx_cm as a double


% --- Executes during object creation, after setting all properties.
function cpx_cm_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cpx_cm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function cpy_cm_Callback(hObject, eventdata, handles)
% hObject    handle to cpy_cm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cpy_cm as text
%        str2double(get(hObject,'String')) returns contents of cpy_cm as a double


% --- Executes during object creation, after setting all properties.
function cpy_cm_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cpy_cm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function OrH_Callback(hObject, eventdata, handles)
% hObject    handle to OrH (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of OrH as text
%        str2double(get(hObject,'String')) returns contents of OrH as a double


% --- Executes during object creation, after setting all properties.
function OrH_CreateFcn(hObject, eventdata, handles)
% hObject    handle to OrH (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function XPosH_Callback(hObject, eventdata, handles)
% hObject    handle to XPosH (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of XPosH as text
%        str2double(get(hObject,'String')) returns contents of XPosH as a double


% --- Executes during object creation, after setting all properties.
function XPosH_CreateFcn(hObject, eventdata, handles)
% hObject    handle to XPosH (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function YPosH_Callback(hObject, eventdata, handles)
% hObject    handle to YPosH (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of YPosH as text
%        str2double(get(hObject,'String')) returns contents of YPosH as a double


% --- Executes during object creation, after setting all properties.
function YPosH_CreateFcn(hObject, eventdata, handles)
% hObject    handle to YPosH (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function LenH_Callback(hObject, eventdata, handles)
% hObject    handle to LenH (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of LenH as text
%        str2double(get(hObject,'String')) returns contents of LenH as a double


% --- Executes during object creation, after setting all properties.
function LenH_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LenH (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%
% function [xdeg ydeg] = p2d(xpix, ypix)
%     xdeg = ((xpix-(xwinpix/2))/degperpix)+cpaz;
%     ydeg = ((ypix-(ywinpix/2))/degperpix)+cpel;
% end
%
% function [xpix ypix] = d2p(xdeg, ydeg)
%     xpix = ((xdeg-cpaz)*degperpix)-(xwinxpix/2);
%     ypix = ((ydeg-cpel)*degperpix)-(ywinypix/2);
% end
%
% function xdeg = p2dx(xpix)
%     xdeg = ((xpix-(xwinpix/2))/degperpix)+cpaz;
% end
%
% function ydeg = p2dy(ypix)
%     ydeg = ((ypix-(ywinpix/2))/degperpix)+cpel;
% end
%
% function xpix = d2px(xdeg)
%     xpix = ((xdeg-cpaz)*degperpix)-(xwinxpix/2);
% end
%
% function ypix = d2py(ydeg)
%     ypix = ((ydeg-cpel)*degperpix)-(ywinypix/2);
% end
%

function BackLum_Callback(hObject, eventdata, handles)
% hObject    handle to BackLum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of BackLum as text
%        str2double(get(hObject,'String')) returns contents of BackLum as a double


% --- Executes during object creation, after setting all properties.
function BackLum_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BackLum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function mask_Callback(hObject, eventdata, handles)
% hObject    handle to BackLum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of BackLum as text
%        str2double(get(hObject,'String')) returns contents of BackLum as a double


% --- Executes during object creation, after setting all properties.
function mask_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BackLum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
