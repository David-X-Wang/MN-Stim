function x_filtered = BNstim_deArt(x,Fs)
warning off
NoiseFreq = 60;
ArtFreq1 = 100;
ArtFreq2 = 150;
NoiseFreqHar = NoiseFreq*[1:8];
ArtFreqHar1 = ArtFreq1*[1:5];
ArtFreqHar2 = ArtFreq2*[1:5];

for i = 1:length(NoiseFreqHar)
    x = bandstop(x',[NoiseFreqHar(i)-2 NoiseFreqHar(i)+2],Fs,'Steepness',0.95)';
end

for i = 1:length(ArtFreqHar1)
    x = bandstop(x',[ArtFreqHar1(i)-2 ArtFreqHar1(i)+2],Fs,'Steepness',0.95)';
end

for i = 1:length(ArtFreqHar2)
    x = bandstop(x',[ArtFreqHar2(i)-2 ArtFreqHar2(i)+2],Fs,'Steepness',0.95)';
end

x_filtered = x;
end