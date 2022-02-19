%% Phase Lock Automated Retrieval - Pranish Kantak Last Updated - 10/30/2018

%{
Use this code once all of the spiketimes have been extracted and Modal
has been completed. Set path to subject's main directory.  Set
directories and filter event structure for successfully retrieved words.
This script is for electrode-level analysis.
%}
ccc;
%% set root directory & make sure raw data is on path
root_dir = dir2 ('/Users/Pranish/Desktop/FR1_Local_Data/Have_Events'); % have to use the custom function dir2 because of the presence of '.','..','.DS_Store'; make sure to check the output in case there is more #s
addpath(genpath('/Users/Pranish/Desktop/FR1_Local_Data')); % set this to the main data directory
%% Begin analysis
tic
cluster_class_retrieved_cat = [];

for subjdir = root_dir'
    
    current_dir = [subjdir.folder filesep subjdir.name];
    cd(current_dir)
    
    subject = subjdir.name;
    lfp_files = dir2('Modal/Modal_NS3_*.mat');
    pos_files=dir2('SpikeTimes_Pos/times_*.mat');
    neg_files=dir2('SpikeTimes_Neg/times_*.mat');
    load(sprintf('%s/Behavioral/events_LFP.mat',current_dir));
    events = events(cellfun(@(x) ~isempty(x), {events.eegfile}'));
    
    % filter for successfully retrieved events
    retEv = filterStruct(events,'intrusion == 0');
    
    for pos_or_neg=[pos_files;neg_files]'
        load([pos_or_neg.folder filesep pos_or_neg.name])
        for current_lfp=lfp_files'
            load([current_lfp.folder filesep current_lfp.name])
            
            
            % script that identifies no spikes, sets cluster class as 0,
            % so this deals with that
            if any(cluster_class(:,1)) == 1
                
                
                % grab the unique clusters for indexing
                
                clusters = unique(cluster_class(:,1))';
                
                
                
                % grab spikes that occur 1000 ms before each successful retrieval event
                for n = 1:length(retEv)
                    
                    spikesIwant = ((cluster_class(:,2) >= ((retEv(n).eegoffset)) & (cluster_class(:,2) <= ((retEv(n).eegoffset) + 1000))));
                    cluster_class_retrieved = cluster_class(spikesIwant,:);
                    
                    cluster_class_retrieved_cat = [cluster_class_retrieved_cat;cluster_class_retrieved];
                    
                end
                
                % round spikeTimes in cluster_class_retrieved to the nearest .5 millisecond
                tmp = cluster_class_retrieved_cat(:,1);
                tmp1 = round((cluster_class_retrieved_cat(:,2))*2)/2;
                cluster_class_retrieved = cat(2,tmp,tmp1);
                clear tmp tmp1
                
                
                cluster_split = {};
                for i = clusters
                    
                    temp = cluster_class_retrieved(:,1) == i;
                    cluster_split{i} = double(cluster_class_retrieved(temp,:));
                    if i >= 2
                        if isempty(cluster_split{i-1})
                            cluster_split{i-1} = nan(1,2);
                        end
                    end
                    
                    % get rid of clusters that spike below 0.5 hz for the whole trial
                    
                    tmp = cluster_class == i;
                    tmp1 = cluster_class(tmp,:);
                    if size(tmp1,1)/((events(end).eegoffset - events(1).eegoffset)/1000) < 0.5
                        cluster_split{i} = nan(1,2);
                    end
                    
                end
                clear tmp tmp1
                % convert spikeTimes in cluster_class_retrieved to seconds; then convert to sample number
                cluster_split_retrieved_samples = {};
                for i = clusters
                    tmp{i} = cluster_split{:,i}(:,1);
                    tmp2{i} = ((cluster_split{:,i}(:,2)) * 2);
                    cluster_split_retrieved_samples{i} = cat(2,tmp{i},tmp2{i});
                    cluster_split_retrieved_samples{i} = round(cluster_split_retrieved_samples{:,i});
                    
                    if i >= 2
                        if isempty(cluster_split_retrieved_samples{i-1})
                            cluster_split_retrieved_samples{i-1} = nan(1,2);
                        end
                    end
                end
                
                clear tmp tmp1 tmp2
                % create a logical cell array; merge this with the bandphase
                % NOTE: Be careful here: if "clusters" skips a number, there still will be
                % an empty cell. Should be taken care of by the "any" statement in the next
                % line.
                
                % this is just a check for empty clusters in the logical. For example,
                % if the clusters for retrieval events are 1,2,3,5,6 - this should tell you
                % that the 4th row of your logical is all 0's and pause the script. Press
                % any button to proceed
                
                Bandphase_size = size(bandphase,2);
                Bandphase_logical = false((size(clusters,2)),Bandphase_size);
                for i = clusters
                    
                    if all(isnan(cluster_split_retrieved_samples{1,i}))
                        continue
                    else
                        
                        Bandphase_logical(i,cluster_split_retrieved_samples{:,i}(:,2)) = true;
                    end
                    if any(Bandphase_logical(i,:)) == 0
                        disp(['Empty Cluster'])
                        pause
                        continue
                    end
                    
                    
                end
                
                
                % preallocate - and compute the rayleigh statistic for each band and each
                % cluster...each row of C is a cluster, each row is a band
                S = [size(bandphase,1),size(Bandphase_logical,1)];
                C = cell(S);
                phases_nonan = cell(C);
                phases = cell(phases_nonan);
                pval = cell(C);
                z = cell(C);
                polarhistograms = cell(C);
                mu = cell(C);
                ul = cell(C);
                ll = cell(C);
                for ii = 1:S(1)
                    for jj = 1:S(2)
                        tmp = bandphase(ii,:);
                        C{ii,jj} = tmp(Bandphase_logical(jj,:));
                        
                        phases_nonan{ii,jj} = ~isnan(C{ii,jj});
                        phases{ii,jj} = C{ii,jj}(phases_nonan{ii,jj});
                        
                        if isempty(phases{ii,jj}) == 1
                            phases{ii,jj} = nan;
                            mu{ii,jj} = nan;
                            ul{ii,jj} = nan;
                            ll{ii,jj} = nan;
                            pval{ii,jj} = nan;
                            z{ii,jj} = nan;
                            polarhistograms{ii,jj} = nan;
                            
                            continue
                            
                        else
                            polarhistograms{ii,jj} = polarhistogram(phases{ii,jj},19);
                            [pval{ii,jj}, z{ii,jj}] = circ_rtest(phases{ii,jj});
                            
                            [mu{ii,jj}, ul{ii,jj}, ll{ii,jj}] = circ_mean(phases{ii,jj},[],2);
                            close all
                            clear tmp
                            
                            
                        end
                    end
                end
                
                
                % in order to delete the empty columnns from neurons that were
                % excluded from the analysis based on firing rates
                
                if any(all(cellfun(@(x) isempty(x), pval),1))
                    pval = pval(:,~all(cellfun(@(x) isempty(x), pval),1));
                    z = z(:,~all(cellfun(@(x) isempty(x), pval),1));
                end
                
                
                % then save output %
                if any(strfind(pos_or_neg.folder,'Pos'))
                    savename = fullfile(sprintf('/Users/Pranish/Desktop/FR1_Local_Data/Have_Events/%s/Analysis_Retrieval/Pos/%s_%s.mat',subject, strrep(strrep(pos_or_neg.name, '.mat',''),'times_',''), strrep(strrep(current_lfp.name, '.mat',''),'Modal_','')));
                elseif any(strfind(pos_or_neg.folder,'Neg'))
                    savename = fullfile(sprintf('/Users/Pranish/Desktop/FR1_Local_Data/Have_Events/%s/Analysis_Retrieval/Neg/%s_%s.mat',subject, strrep(strrep(pos_or_neg.name, '.mat',''),'times_',''), strrep(strrep(current_lfp.name, '.mat',''),'Modal_','')));
                end
                
                
                if ~isempty(phases) == 1
                    save(savename,'pval','z','mu','ul','ll','bands','phases','frequency_sliding','pos_or_neg','current_lfp','clusters');
                    clearvars -except cluster_class_retrieved_cat current_dir subject lfp_files pos_files neg_files events retEv pos_or_neg current_lfp cluster_class;
                    
                    
                elseif any(cluster_class(:,1)) == 0
                    
                    continue
                end
            end
        end
    end
end
toc