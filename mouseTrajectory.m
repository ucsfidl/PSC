function mouseTrajectory(infile)
% mouseTrajectory reads the output of mouseListener_rt and analyzes and plots it

if(nargin < 1)
    [FileName,PathName,FilterIndex] = ...
        uigetfile('*.mat','File made by mouseListener_rt');
    infile = fullfile(PathName, FileName);
end
load(infile);
rigSpecific;

%% Now compute trajectory and actual speed 

cvx = double(dX);
cvy = double(dY);

if runningexpt ==1
    m1 = dChannel ==1;
    m2 = dChannel ==2;
else
    m1 = dChannel==0;
    m2 = dChannel==1;
end

M1_X = cumsum(cvx(m1));
M2_X = cumsum(cvx(m2));
M1_Y = cumsum(cvy(m1));
M2_Y = cumsum(cvy(m2));

% resample data into even time intervals dtime
M1_T = dT(m1);
M2_T = dT(m2);
dtime = 0.1;
Tmax = min(max(M1_T),max(M2_T));
Tmin =max(min(M1_T),min(M2_T));

tsamp = Tmin:dtime:Tmax;
M1_Xsamp = interp1(M1_T,M1_X,tsamp);
M2_Xsamp = interp1(M2_T,M2_X,tsamp);
M1_Ysamp = interp1(M1_T,M1_Y,tsamp);
M2_Ysamp = interp1(M2_T,M2_Y,tsamp);

M1_dXsamp = diff(M1_Xsamp);
M2_dXsamp = diff(M2_Xsamp);
M1_dYsamp = diff(M1_Ysamp);
M2_dYsamp = diff(M2_Ysamp);

% calculate real-world position by integrating head orientation
% and forward/orthogonal movement
%scale_factor is now tickspercm in rigSpecific

plotOn = 1;

theta =zeros(size(M1_dYsamp));
x=zeros(size(M1_dYsamp)); y=zeros(size(M1_dYsamp));

length(M2_dXsamp);
find(isnan(M2_dXsamp));

dTheta=-2*pi*0.5*(M1_dXsamp+M2_dXsamp)/C;
M2_dYsamp =-1*M2_dYsamp;  %%% to keep axes following righthand rule
M1_dYsamp =-1*M1_dYsamp;  %%% because mouse is in front on 2p scope
theta(1)=0+dTheta(1);
x(1)=0+M1_dYsamp(1);
y(1) = 0+M2_dYsamp(1);
for t=2:length(M1_dYsamp);
    x(t) = x(t-1) + M1_dYsamp(t-1)*cos(theta(t-1)) - M2_dYsamp(t-1)*sin(theta(t-1));
    y(t) = y(t-1) + M1_dYsamp(t-1)*sin(theta(t-1)) + M2_dYsamp(t-1)*cos(theta(t-1));
    theta(t) = theta(t-1)+dTheta(t);
end


%%% plot trajectory
if plotOn
    figure
    plot(x/tickspercm,y/tickspercm)
    title('trajectory')
    axis equal
end

if plotOn
    figure
    plot(theta);
    title('theta')
    ylabel('radians')
end

%%% plot velocity as a function of time
v = sqrt(diff(x).^2 + diff(y).^2)/(tickspercm*dtime);
vsmooth = conv(v,ones(1,11))/10;
vsmooth=vsmooth(6:length(vsmooth)-4);
tsamp = tsamp(1:length(tsamp)-1)+dtime/2;
v_thresh = 0.03*max(vsmooth);

if plotOn
    figure
    plot(tsamp,vsmooth,'g')
	title('speed')
    xlabel('secs');
    ylabel('cm/sec');
    if exist('dRunning','var')
        hold on
        plot(dT,dRunning,'Color','red');
        hold off
    end
        
end

total_distance = sum(vsmooth)/(100*tickspercm*dtime);

disp(sprintf('ran %f meters in %f mins',total_distance,max(tsamp)/60));
disp(sprintf('stationary = %f mins; moving = %f mins',sum(vsmooth<v_thresh)*dtime/60,sum(vsmooth>v_thresh)*dtime/60));
if sum((v>v_thresh)>0)  %%% to avoid divide by 0
    disp(sprintf('average moving speed = %f cm/sec \n ',mean(vsmooth(vsmooth>v_thresh))));
end