% The 5 computers involved must be defined for each rig
psychstimhost = 'mps-pc39.cin.ucsf.edu'; % runs PsychStimController
% psychstimhost2 = 'mps-pc12.cin.ucsf.edu'; % runs PsychStimController
trackballhost = 'localhost' %'mps-pc7.cin.ucsf.edu'; %the computer running mouseListener
stimsynchost =  'localhost' ; % 'mps-pc21.cin.ucsf.edu' the Arduino or RPi that converts a UDP to a TTL out
runninghost = psychstimhost; % computer that receives running/still input to control visual stimulus, same as PSC
%runninghost2 = psychstimhost2; % computer that receives running/still input to control visual stimulus, same as PSC
eyecamhost = 'localhost'; % '169.230.188.82'computer running GrabCPP ; receives times from PSC
intanhost = '' ;% computer hosting the Intan, receives TTL input only for synchronization.
%RPihost = 'mps-rpi4.cin.ucsf.edu' %must be set to REAL Rpi name or IP address
% RPihost2 = 'mps-rpi3.cin.ucsf.edu' %must be set to REAL Rpi name or IP address

% The computer below is defined for mapping with ContImage
contImageHost = 'localhost'; % temporary redirect to matlab udpmon
tdtHost = 'localhost'; % changed 03/11/15 by MCD
shutterHost = 'localhost';

%Ports never need to be changed
stimsyncport = 8934;
runningport = 8938;
trackballport = 8939;
RPiSelfport = 8888;
RPiport1 = 8931;

% RPiport2 = 8932;

%added MPS 2016Aug15 for sending UDP to the pupil camera both filename and
%times to snap picture.
eyecamport = '8935'  ;

contImagePort = 8936;
tdtPort = 8933;
shutterPort = 2424;
WFCAPort = 8932;
%changed MPS 2016Jan06.  Set to appropriate room
room = 'UCSF460G';

%added MPS 2016Jan06 for Intan to allow different kinds of sync in different rigs
% 'LPT' is Maria's in 460A parallel port
% 'SER' is Shinya's at UCSC using a matlab toolbox
% 'UDP' is Michael's using an Arduino board like mps-pc21 using the program UDP2TTL
stimsync = 'WFC';
stimsynchost = 'mps-pc48.cin.ucsf.edu'; %WFCAhost = 'mps-pc48.cin.ucsf.edu'; the Widefield Imaing computer 
stimsyncport = 8932;

% stimsync = 'SER';
% stimsync = 'UDP';

trackballfolder = 'C:\2pdata\Trackball\';

%added MPS 2016July05 to set folder for storing sync data
stimsyncfolder = 'C:\stim\'

%added MPS 2016July05 selector for stimulus specificity test 
%runningexpt= 0 is normal; runningexpt=1 makes stimulus contingent on locomotion)
runningexpt = 0;
C=6000;  % circumference in ticks for new small mice used with RPi
tickspercm = C/(pi*20);  %%% ball is 20 cm diameter, so this is ticks/cm
oldGraphics = 1;


