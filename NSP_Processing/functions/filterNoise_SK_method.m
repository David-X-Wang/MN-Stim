function [newPow, newEvents] = filterNoise_SK_method(pow, events, peakThresh, sampFreq)

% This function will filter the data with the time window of length windowDur and stringency peakThresh

% Do this by session because the noise can change from session to session

unEEG = unique({events.eegfile}');
filteredPow = [];
filteredEvents = [];
for eegInd = 1:size(unEEG,1)
    
    sess_vect = cellfun(@(x) strcmp(x, unEEG{eegInd,1}), {events.eegfile}');
    sess_ev = events(sess_vect);
    if size(pow,3) >1
        sess_pow = pow(sess_vect,:,:);
    else
        sess_pow = pow(sess_vect,:);
    end
    
    % Clean noise
    tempPow = cleanNoisyPeaksInPeriodogram(sess_pow,peakThresh, sampFreq);
    
    filteredPow = cat(1, filteredPow, tempPow);
    filteredEvents = cat(2, filteredEvents, sess_ev);
    clear vars   sess_ev sess_vect sess_pow num_rows tempPow
end

newPow = filteredPow;
newEvents = filteredEvents;

end

