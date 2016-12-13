%% Hand mapping externalized as a script...

%% clear screen
        incre = white-grey;
        Screen('FillRect',window,grey);
        Screen('DrawText',window,sprintf('Hand'),10,40);
        Screen('Flip',window);
        
        % spot
        radius = 50;
        tf = 1; % flashing frequency in Hz
        x = -1500:0.5:1500;
        
        % key assignment
        esc = KbName('esc'); % Esc -- 27 for exiting mapping <- switch back to on 02/2015 mcd
%         esc = KbName('ESCAPE'); % Esc -- 27 for exiting mapping
        uarrow = KbName('up'); % Up Arrow -- 38 for increasing radius
        darrow = KbName('down'); % Down Arrow -- 40 for decreasing radius
%         uarrow = KbName('UpArrow'); % Up Arrow -- 38 for increasing radius
%         darrow = KbName('DownArrow'); % Down Arrow -- 40 for decreasing radius
        f = KbName('f'); % F -- ?? for higher flashing frequency
        s = KbName('s'); % S -- 83 for lower flashing frequency
        q = KbName('q'); % Q -- 81 for square wave
        m = KbName('m'); % for mouse hide/show mode
        n = KbName('n'); % for mouse hide/show mode
        b = KbName('b'); % for black background
        w = KbName('w'); % for white background
        g = KbName('g'); % for grey background
        
        
        [keyisdown,secs,keycode] = KbCheck;
        HideCursor;
        
        waitframes = 1;
        handduration = 1200; % maximum time duration
        ifi = Screen('GetFlipInterval',window);
        lum = grey+incre*sin(4*pi*tf*ifi*x); % initialize -- sinusoidal
        
        Screen('TextFont',window,'Arial'); % font
        Screen('TextSize',window,10); % size
        vbl = Screen('Flip',window);
        vblendtime = vbl+handduration;
        j = 1;
        mousemode = 0;
        bg = 0.5;
        while ~keycode(esc) && (vbl < vblendtime)
            [xpos,ypos,buttons] = GetMouse(window);
            [keyisdown,secs,keycode] = KbCheck;
            if keycode(uarrow)
                radius = radius+1;
            end
            if keycode(darrow)
                radius = radius-1;
            end
            if radius == 0
                radius = 50;
            end
            if keycode(f)
                tf = tf+0.1;
                lum = grey+incre*sin(4*pi*tf*ifi*x);
            end
            if keycode(s)
                tf = tf-0.1;
                if tf < 0
                    tf = 0;
                end
                lum = grey+incre*sin(4*pi*tf*ifi*x);
            end
            if keycode(q)
                lum(lum >= grey) = white;
                lum(lum < grey) = black; % for square-wave
            end
            if keycode(b)
                Screen('FillRect',window,black);
                bg = 0;
            end
            if keycode(w)
                Screen('FillRect',window,white);
                bg = 1;
            end
            if keycode(g)
                Screen('FillRect',window,grey);
                bg = 0.5;
            end
            if keycode(m)   % toggle mouse mode
                mousemode = 1;
            end
            if keycode(n)
                mousemode = 0;
            end
            
            if mousemode == 0
                Screen('FillOval',window,[lum(j) lum(j) lum(j)],[xpos-radius ypos-radius xpos+radius ypos+radius]);
            else % mousemode == 1
                if any(buttons)  %%%% if button pressed, fill the oval
                    if bg == 0.5 %%% grey background. buttons 1&3 do white/black
                        if buttons(1)
                            Screen('FillOval',window,white,[xpos-radius ypos-radius xpos+radius ypos+radius]);                           
                        elseif buttons(3)
                            Screen('FillOval',window,black,[xpos-radius ypos-radius xpos+radius ypos+radius]);
                        end
                    else %%% white/black background.
                        if buttons(1)
                            Screen('FillOval',window,(white-black)*(1-bg),[xpos-radius ypos-radius xpos+radius ypos+radius]);
                        end                        
                    end                                
                else %%%% no buttons pressed. fill oval with scaled background
                    Screen('FillOval',window,(white-black)*bg,[xpos-radius ypos-radius xpos+radius ypos+radius]);
                end
                
            end
%            text1 = ['Pos:' '(' num2str(xpos) ', ' num2str(ypos) ')' ',R:' num2str(radius) ',TF:' num2str(tf) 'Hz'];
% Stryker
% pixel corresponding to cp in x:  (xcp/screenwidth)*xwinpix
% pixel corresponding to cp in y:  (ycp/screenheight)*ywinpix

%             xposdeg = ((xpos-(xwinpix/2))*degPerPix) + azcp;
%             yposdeg = (-1*((ypos-(ywinpix/2))*degPerPix)) + elcp;
            cpx_cm = str2double(get(handles.cpx_cm,'String')); 
            cpy_cm = str2double(get(handles.cpy_cm,'String')); 
            SizeX = str2double(get(handles.SizeX,'String')); 
            SizeY = str2double(get(handles.SizeY,'String')); 

            xposdeg = ((xpos-((cpx_cm/SizeX)*xwinpix))*degPerPix) + azcp;
            yposdeg = (-1*((ypos-((cpy_cm/SizeY)*ywinpix))*degPerPix)) + elcp;
            
            % darcy: use diameter, not radius. makes more senses with spot
            % stim 'length'
            radiusdeg = 2 * radius * degPerPix;
            text1 = ['Pos (deg):' '(' num2str(xposdeg) ', ' num2str(yposdeg) ')'...
                'Pos (px):' '(' num2str(xpos) ', ' num2str(ypos) ')'...
                ',R:' num2str(radiusdeg) ',TF:' num2str(tf) 'Hz'];
            Screen('DrawText',window,text1,40,40,0.2*(white-black));
            vbl = Screen('Flip',window,vbl+(waitframes-0.5)*ifi);
            j = j+1;
            if j == size(x,2)
                j = 1; % restart a new cycle
            end
        end
        
        %%% cleanup
        Priority(0);
        moglClutBlit;
        ListenChar(1); %%% needed to regain keyboard control
        Screen('LoadNormalizedGammaTable',window,flat_clut);
        Screen('CloseAll');
        
        %%% return x,y,rad and orientation to guide
%         set(handles.XPosH,'String',num2str(xpos));
%         set(handles.YPosH,'String',num2str(ypos));
%         set(handles.LenH,'String',num2str(radius));
% Stryker 2012Jan31
        set(handles.XPosH,'String',num2str(xposdeg,'%3.0f'));
        set(handles.YPosH,'String',num2str(yposdeg,'%3.0f'));
        set(handles.LenH,'String',num2str(radiusdeg,'%3.0f'));
        set(handles.OrH,'String',num2str(0)); %%% sept 23 '11 - implement later
        
        ShowCursor;        
        %%% End of Hand Mapping
