% Blackrock CereStim R96 stimulation script
% This script generates the BN (binary noise) stimulation patterns using 
% the pre-defined parameters for cerestim stimulator. The stim signal is  
% a sequence of alter-amplitude biphasic pulses. 
% HighAmp : The current of high amplitude biphasic pulse
% LowAmp :  The current of low amplitude biphasic pulse
% StimFreq : Frequency of biphasic High/Low biphasic pulses
%
% BNpattern : The pseudo-binary noise pattern (p=0.5) that each sample
%             point has NumPulses of difined High/Low stim pattren.
%
% BNsequence : The BN sequence has the same length as the actual signal. It 
%              can be seen as the modulation signal (multiplied by single pulse)              
%              and the enovlop of actual stim signal goes to the brian.
%              Saved in script for later system identification. BNsequence
%              is also sampled to match the sampling frequency in data acquisition (1Ks/sec)
%
% David Wang 
% Latest update : March/2021
% Change log : Apirl 2021, added the 2nd stim frequency 

%%%%%%%%%%%%%%%%%%%%% BN modulation pattern save path %%%%%%%%%%%%%%%%%%%%%
Subject = 'UT999';      % Subject Number, UT999 for testing
SessionNum = 0;         % Test Session Number. If a session is interrupted,
                        % please start with a new session number. (Same in BlackRock Central)
                        
SavePath = ['C:\data\',Subject,'\session_',num2str(SessionNum),'\'];
if ~exist(SavePath, 'dir')
    mkdir(SavePath)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%% Define  parameters for stim sequence  %%%%%%%%%
StimChannel = 1;        % Channel No. for stim signal (PCC electrode)
StimRecChannel = 2 ;    % Channel No. for recording stim signal (only if necessary, would need physical wiring)
NumEvents = 90;         % 90 events for a 1-hour session, each event is 40s long, (20s of stim and 20s no-stim)

HighAmp = 2000;          % Amplitude for high current pulses, in uA
LowAmp = 1000;           % Amplitude for low current pulses, in uA
HighFreq = 100;          % Freuqnecy for stimulation pulse, 100Hz
LowFreq = 150;

Tsw = 0.2;
StimDuration = 5;      % stim duration, in seconds
NoPattern = StimDuration/Tsw;

NumPulses1 = Tsw/(1/HighFreq);         % number of pulses per modulation, to minic the random BN pattern
NumPulses2 = round(Tsw/(1/LowFreq));
WaitDuration = 5;      % baseline duration, in seconds

%%%%%%%%%%%%%%%%%%%%%%%%%%%% Define Stim Pulse %%%%%%%%%%%%%%%%%%%%%%%%%%%%
% High-amplitude-high-frequency stim pulse  
stimulator.setStimPattern('waveform',1,'polarity',0,'pulses',NumPulses1,'amp1',HighAmp, ...
    'amp2',HighAmp, 'width1',200,'width2',200,'interphase',55,'frequency',HighFreq);
% Low-amplitude-high-frequency stim pulse  
stimulator.setStimPattern('waveform',2,'polarity',0,'pulses',NumPulses1,'amp1',LowAmp, ...
    'amp2',LowAmp, 'width1',200,'width2',200,'interphase',55,'frequency',HighFreq);
% High-amplitude-low-frequency stim pulse  
stimulator.setStimPattern('waveform',3,'polarity',0,'pulses',NumPulses2,'amp1',HighAmp, ...
    'amp2',HighAmp, 'width1',200,'width2',200,'interphase',55,'frequency',LowFreq);
% Low-amplitude-low-frequency stim pulse  
stimulator.setStimPattern('waveform',4,'polarity',0,'pulses',NumPulses2,'amp1',LowAmp, ...
    'amp2',LowAmp, 'width1',200,'width2',200,'interphase',55,'frequency',LowFreq);


%%%%%%%%%%%%%%%%%%%%%% Define Stim Sequence %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Fs =1000;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Send out stim %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1:NumEvents 
    pause(WaitDuration)                                                    % Start baseline duration of 20s
    tStart = tic;
    stimulator.beginSequence();                                            % begin a sequence for cerestim
    %stimulator.wait(WaitDuration*1000);                                   
    BNpattern = randi([1 4],[1 NoPattern]);                                 % Generate pseudo-binary noise pattern
    %plot(BNpattern)
    BNamp = repelem((HighAmp-LowAmp)*(rem(BNpattern,2)==1)+LowAmp,Fs*Tsw);  
    %figure;plot(BNamp)
    BNfreq = repelem((HighFreq-LowFreq)*(BNpattern<3)+LowFreq,Fs*Tsw);
    %figure;plot(BNfreq)
    BNsequence = [BNamp BNfreq];     % Generate BN sequence. 
    
    save([SavePath,sprintf('BN_StimPattern_%03d.mat',i)],'BNPattern')      % THIS IS SAVED FOR LATER CONTROL
    for SeqInd = 1:length(BNpattern)
        stimulator.autoStim(StimChannel,BNpattern(SeqInd));
    end
    stimulator.endSequence();    
    stimulator.play(1);
    fprintf('BN sequence %03d/%03d are generated and saved\n',i,NumEvents)
    tEnd = toc(tStart);
    pause(StimDuration+tEnd)                                               % Pause for Cerestim to finish ongoing task, other wise micro-controller will stop
end


tStart  = tic ;
plot(TimeVec,BNsequence/1000)
ylim([0,HighAmp*1.5/1000])
ylabel('Amplitude (mA)')
xlabel('Time (s)')
title('Stim Modulation Sequence')
tEnd = toc(tStart) ;
TimeVec = linspace(0,20,StimDuration*Fs);


%stimulator.stop();

