function [img lut]= generateCurvGratings_lut(orientval,freq,TempFreq,phase0,contrast,duration,degPerPix,sizeX,sizeY,frameRate,black,white,sizeLut,PosX,PosY,radiusdeg,typecurve)%generateCurvGratings_lut(handles.orient(c),handles.freq(c),handles.TempFreq(c),handles.phase(c),handles.contrast(c),Duration, degPerPix,imageRect(3),imageRect(4),FrameHz,black,white,sizeLut,handles.positionX(c),handles.positionY(c),handles.length(c),handles.speed(c))%%% generate images for drifting gratings, without displaying them%%% based (loosely) on DriftDemo from psychtoolbox%%% cmn 11/05/05% 2/21/02 dgp Wrote it, based on FlickerTest.% 4/23/02 dgp HideCursor & ShowCursor.% 9/7/16 ld Curved gratingsorientval = orientval*pi/180; % conver to rad.backgroundcol = 0;% windowgray = 0.5*(white + black);if contrast > 1    contrast = 1;endinc = (white-gray)*contrast;%%% calculate stimulus parametersframes = duration*frameRate;  % temporal period, in frames, of the drifting grating%%%framesPerPeriod = frameRate / (TempFreq); use inverse of this to avoid%%%dividing by zero when tempfreq=0FrameFreq = TempFreq/frameRate;   %%%grating frequency, in frames;wavelength = 1/freq;pixPerDeg = 1/degPerPix;f = 2*pi/(pixPerDeg*wavelength); % cycles/pixel%%PARAMETERS%% (these are fixed now, but should be selected from the GUI) stim_centerX = round(PosX*pixPerDeg);%in pixels for now, could also be given as degrees and convertedstim_centerY = round(PosY*pixPerDeg);%in pixels for now, could also be given as degrees and convertedS_curve = typecurve;% 1 - curve, 2 - s-curve, 3 - angleR = round(pixPerDeg*radiusdeg);%convert circle radius from degrees to pixelsvlength = 2*R; %choose "vertical" length of the stimulus (should be at least 2 times the radius  % -- increase this according to needs) --> could also be an argument to this function   %make sure it's evenvlength = floor(vlength/2)*2;%%POSITIONING%%%find start and end positions in each coordinatestartX = stim_centerX - R;Xinc1 = 0;%make sure img dimensions are big enough for the entire semi-circleif startX < 1    Xinc1 = - startX;    sizeX = sizeX + Xinc1;    stim_centerX = stim_centerX - startX;    startX = 1;endendX = stim_centerX + R;Xinc2 = 0;if endX > sizeX    Xinc2 = endX - sizeX;    sizeX = endX;    stim_centerX = stim_centerX + endX - sizeX;endstartY = stim_centerY - vlength/2;Yinc1 = 0;if startY < 1    Yinc1 = - startY;    sizeY = sizeY + Yinc1;    stim_centerY = stim_centerY - startY;    startY = 1;endendY = stim_centerY + vlength/2 - 1;%make sure we select a region whose height is an integer multiple of the%sawtooth period:endY = endY + mod(vlength,round(1/f)); % f is cycles per degree - (1/f) degpercycleYinc2 = 0;if endY > sizeY    Yinc2 = endY - sizeY;    sizeY = endY;    stim_centerY = stim_centerY + endY - sizeY;end%%SAWTOOTH%%% calculate image, a ramp from 0 to 2pi aligned with grating[x y] = meshgrid(1:sizeX, 1:sizeY);%(start with horizontal gratings, we'll rotate them later)a = cos(pi/2)*f;b = sin(pi/2)*f;img = floor(mod(a*x + b*y + phase0*pi/180, 2*pi) * (sizeLut-1)/(2*pi))+1; %paint the rest in blackfor i=[1:(startY-1) (endY+1):sizeY]    img(i,:) = backgroundcol;endfor i=[1:(startX-1) (endX+1):sizeX]    img(:,i) = backgroundcol;end%%CURVE%%%displace columns vertically ("up-shifts") to create the semi-circlesif S_curve == 1%regular semicircle    for i=startX:endX%move from left to right        x = (i-startX)/(R) - 1;        t = acos(x);        shift = -R*sin(t);%amount to shift%         img(:,i) = circshift(img(:,i),round(shift),1); % old - LD        img(:,i) = circshift(img(:,i),round(shift)); % new - MCD    endelseif S_curve == 2    %draw an S-curve by flipping half the semicircle vertically    for i=startX:stim_centerX        x = (i-startX)/(R) - 1;        t = acos(x);        shift = -R*sin(t);%amount to shift%         img(:,i) = circshift(img(:,i),round(shift),1); % old - LD        img(:,i) = circshift(img(:,i),round(shift)); % new - MCD    end    for i=stim_centerX+1:endX%move from left to right        x = (i-startX)/(R) - 1;        t = acos(x);        shift = -R - (R - R*sin(t));%         img(:,i) = circshift(img(:,i),round(shift),1); % old - LD        img(:,i) = circshift(img(:,i),round(shift)); % new - MCD    endelse    % ANGLED STIMULI HEREend%paint the bottom in black again in case part of the circles rotated around%the imagefor i=[(endY+1):sizeY]     img(i,:) = backgroundcol;end%figure;imshow(img./255)%%ROTATION%%%get center of imagecenterX = floor(sizeX/2+1);centerY = floor(sizeY/2+1);%compute new stim_centers after rotation around the image centernewX = centerX + (stim_centerX-centerX)*cos(orientval) - (centerY-stim_centerY)*sin(orientval);newY = centerY - (stim_centerX-centerX)*sin(orientval) - (centerY-stim_centerY)*cos(orientval);%get deltas in each coordinatedeltaX = round(stim_centerX - newX);deltaY = round(stim_centerY - newY);%use padding to prevent stimulus from ending up outside of the screen if its center%  is too close to the borderpadded_img = padarray(img, [abs(deltaY) abs(deltaX)]);%rotate it about the image centerrotated_img = imrotate(padded_img, orientval*180/pi, 'nearest', 'crop');%cut the appropriate region, as if the img had been rotated around the point (stim_centerX,stim_centerY)%  (cut out the padding we introduced and compensate for the deltas in each coordinate)img_full = rotated_img(abs(deltaY)+1-deltaY:end-abs(deltaY)-deltaY, abs(deltaX)+1-deltaX:end-abs(deltaX)-deltaX);%now restore original image size (in case it was increased earlier)img = img_full(Yinc1+1:end-Yinc2, Xinc1+1:end-Xinc2);%figure;imshow(img./255)%%LOOKUP TABLE%%%%% calculate lookup table, i.e. map phase into sinusoid% ph = (2*pi*(0:(sizeLut-1))/sizeLut)';ph = (2*pi*(0:(sizeLut-1))/sizeLut)';lut =zeros(sizeLut,3,floor(frames));for i=1:frames        phase=(i*FrameFreq)*2*pi;    lu = gray + inc*sin(ph+phase);    lu(1) = gray;    lut(:,:,i) = [lu lu lu];end