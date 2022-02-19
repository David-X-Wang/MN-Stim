Spike_nostim;
Spike_stm;

eg1 = squeeze(Spike_stim(1,:,:));
eg2 = squeeze(Spike_nostim(1,:,:));

figure
plot(eg1')
figure
plot(eg2')

Fs = 1000;
Spike_sitm_filtered = [];
for i = 1:size(Spike_stim,1)
    Spike_sitm_filtered(i,:,:) = BNstim_deArt(squeeze(Spike_stim(i,:,:)),Fs);

end

eg3 = squeeze(Spike_sitm_filtered(1,:,:));


figure
plot(eg3')