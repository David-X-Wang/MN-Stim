% Blackrock CereStim R96 stimulation script
% This script generates the BN (binary noise) stimulation patterns using 
% the pre-defined parameters for cerestim stimulator. The stim signal is  
% a sequence of alter-amplitude biphasic pulses. 
% HighAmp : The current of high amplitude biphasic pulse
% LowAmp :  The current of low amplitude biphasic pulse
% StimFreq : Frequency of biphasic High/Low biphasic pulses
%
% QNpattern : The pseudo-quandanry noise pattern (p=0.25) that each sample
%             point has NumPulses of difined Amp1-Amp4 stim pattren.
%
% QNsequence : The BN sequence has the same length as the actual signal. It 
%              can be seen as the modulation signal (multiplied by single pulse)              
%              and the enovlop of actual stim signal goes to the brian.
%              Saved in script for later system identification. BNsequence
%              is also sampled to match the sampling frequency in data acquisition (1Ks/sec)
%
% David Wang 
% Latest update : March/2022

%%%%%%%%%%%%%%%%%%%%% BN modulation pattern save path %%%%%%%%%%%%%%%%%%%%%
Subject = 'UT999';      % Subject Number, UT999 for testing
SessionNum = 1;         % Test Session Number. If a session is interrupted,
                        % please start with a new session number. (Same in BlackRock Central)
                        
SavePath = ['C:\data\',Subject,'\session_',num2str(SessionNum),'\'];
if ~exist(SavePath, 'dir')
    mkdir(SavePath)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%% Define  parameters for stim sequence  %%%%%%%%%
StimChannel = 1;        % Channel No. for stim signal (PCC electrode)
StimRecChannel = 2 ;    % Channel No. for recording stim signal (only if necessary, would need physical wiring)
NumEvents = 90;         % 90 events for a 1-hour session, each event is 40s long, (20s of stim and 20s no-stim)

Amp1 = 1000;           % Amplitude for high current pulses, in uA
Amp2 = 1500;           % Amplitude for low current pulses, in uA
Amp3 = 2000;           % Amplitude for high current pulses, in uA
Amp4 = 2500;           % Amplitude for low current pulses, in uA

Frequency = 100;         % Freuqnecy 1 for stimulation pulse, 100Hz

Tsw = 0.1;
StimDuration = 3;      % stim duration, in seconds
NoPattern = StimDuration/Tsw;
NumPulses1 = Tsw/(1/Frequency);         % number of pulses per modulation, to minic the random BN pattern
WaitDuration = 3;      % baseline duration, in seconds

%%%%%%%%%%%%%%%%%%%%%%%%%%%% Define Stim Pulse %%%%%%%%%%%%%%%%%%%%%%%%%%%%
% High-amplitude-high-frequency stim pulse  
stimulator.setStimPattern('waveform',1,'polarity',0,'pulses',NumPulses1,'amp1',Amp1, ...
    'amp2',Amp1, 'width1',200,'width2',200,'interphase',55,'frequency',Frequency);
% Low-amplitude-high-frequency stim pulse  
stimulator.setStimPattern('waveform',2,'polarity',0,'pulses',NumPulses1,'amp1',Amp2, ...
    'amp2',Amp2, 'width1',200,'width2',200,'interphase',55,'frequency',Frequency);
% High-amplitude-low-frequency stim pulse  
stimulator.setStimPattern('waveform',3,'polarity',0,'pulses',NumPulses1,'amp1',Amp3, ...
    'amp2',Amp3, 'width1',200,'width2',200,'interphase',55,'frequency',Frequency);
% Low-amplitude-low-frequency stim pulse  
stimulator.setStimPattern('waveform',4,'polarity',0,'pulses',NumPulses1,'amp1',Amp4, ...
    'amp2',Amp4, 'width1',200,'width2',200,'interphase',55,'frequency',Frequency);


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
    BNamp = repelem((Amp2-Amp1)*(BNpattern),Fs*Tsw)+(Amp2-Amp1);  
    %figure;plot(BNamp)
    BNfreq = repelem((Frequency)*ones(size(BNpattern)),Fs*Tsw);
    %figure;plot(BNfreq)
    BNsequence = [BNamp; BNfreq];     % Generate BN sequence. 
    
    save([SavePath,sprintf('BN_StimPattern_%03d.mat',i)],'BNsequence')      % THIS IS SAVED FOR LATER CONTROL
    for SeqInd = 1:length(BNpattern)
        stimulator.autoStim(StimChannel,BNpattern(SeqInd));
    end
    stimulator.endSequence();    
    stimulator.play(1);
    fprintf('BN sequence %03d/%03d are generated and saved\n',i,NumEvents)
    tEnd = toc(tStart);
    pause(StimDuration+tEnd)                                               % Pause for Cerestim to finish ongoing task, other wise micro-controller will stop
end



%stimulator.stop();

