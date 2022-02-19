% Get the data out of the sorted 'sort_cat.h5' files and turn it into
% spikeTimes

session_paths = {'/Users/Pranish/Desktop/FR1_Local_Data/Common_Avg_Referencing/UT113/Raw/8_29_18_FR1_Micro/CAR'};

for ses = 1:length(session_paths)
    cd(session_paths{ses})
    
    % Find all the NSX folders in the directory
    folders = dir(pwd); %gets a list of the files in "folders"
    isub = [folders(:).isdir]; % returns logical vector
    nameFolds = {folders(isub).name}';
    nameFolds(ismember(nameFolds,{'.','..'})) = [];
    
    NS6_idx = strmatch('NS6',nameFolds); % Switch bbetween NSX and CSC 
    for j = 1:length(NS6_idx)
        ns6_path = fullfile(session_paths{ses},nameFolds{NS6_idx(j)});
        cd(ns6_path)
        
        try
            cd('sort_pos_simple') % what bout positive?   'pos'
        catch
            continue
        end
        try
            h5_data = hdf5info('sort_cat.h5');
        catch
            continue
        end
        names = {};
        for i = 1:length(h5_data.GroupHierarchy.Datasets)
            names{i} = h5_data.GroupHierarchy.Datasets(i).Name;
        end
        
        Groups = find(strcmp(names,'/groups'));
        SpkIndex = find(strcmp(names,'/index'));
        
        sortedGroups = hdf5read(h5_data.GroupHierarchy.Datasets(Groups)); %PAK: what does this do?
        sortedIdx = hdf5read(h5_data.GroupHierarchy.Datasets(SpkIndex))+1; %PAK: what does this do?
        skipped = find(diff(sortedIdx+1)>1); % these are the spikes skipped by indexing
        
        clusters = unique(sortedGroups(2,(sortedGroups(2,:)>0)));
        
        % Gets the classes that passed sorting, with the corresponding clusters below
        
        cd(ns6_path)
        orig_data = hdf5info(char(strcat('data_', nameFolds(NS6_idx(j)),'.h5'))); % Get the original spikes and times
        struct_names ={};
        
        for t = 1:length(orig_data.GroupHierarchy.Groups(2).Datasets) % remember, 1 is negative, 2 is positive
            struct_names{t} = [orig_data.GroupHierarchy.Groups(2).Datasets(t).Name];
        end
        
        Times = find(strcmp(struct_names,'/pos/times')); % what if they are positive?     'pos'
        Waveforms = find(strcmp(struct_names,'/pos/spikes'));
        
        spikeWaveforms = hdf5read(orig_data.GroupHierarchy.Groups(2).Datasets(Waveforms));% remember, 1 is negative, 2 is positive
        spikeTimes = hdf5read(orig_data.GroupHierarchy.Groups(2).Datasets(Times));
        spikeClusters = zeros(length(spikeTimes),1);
        
        if isempty(clusters) % this means there were no clusters in this channel
            disp('There were no clusters on this channel')
            cluster_class = [spikeClusters spikeTimes];
            % Set cluster_class to zeros
            
        else
            Classes = find(strcmp(names,'/classes'));
            spikeClasses = zeros(1,length(spikeTimes));
            tempClasses = hdf5read(h5_data.GroupHierarchy.Datasets(Classes)); % Gets the classes for all the initial spikes detected
            
            numClus = length(clusters);
            
            validClasses_Clusters = sortedGroups(:,find(sortedGroups(2,:)>0));
            
            for k = 1:length(sortedIdx);
                spikeClasses(sortedIdx(k)) = tempClasses(k);
                for i = 1:size(validClasses_Clusters,2);
                    if spikeClasses(sortedIdx(k)) == validClasses_Clusters(1,i)
                        spikeClusters(sortedIdx(k),1) = validClasses_Clusters(2,i);
                    end
                end
            end
            
            
            % Get rid of non-sorted 'spikes'
            
            nonSpikes=  ~ismember(int16(spikeClasses),validClasses_Clusters(1,:));
            
            spikeWaveforms(:,nonSpikes) = [];
            spikeTimes(nonSpikes) = [];
            spikeClasses(nonSpikes) = [];
            spikeClusters(nonSpikes) = [];
            
            if size(spikeClusters,2) > 1
                spikeClusters = spikeClusters';
            end
            if size(spikeTimes,2) > 1
                spikeTimes = spikeTimes';
            end
            
            cluster_class = [spikeClusters spikeTimes];
        end
        
        savename = fullfile(char(strcat('times_',nameFolds(NS6_idx(j)))));
        cd(session_paths{ses})
        save(savename,'spikeWaveforms', 'spikeTimes', 'spikeClusters', 'cluster_class'); % change this
    end
end



