clearvars; close all; clc;
warning off 

subj = 'UT247';
sessDir = '5_26_21_SR_Micro';
spikeDir = sprintf('/project/TIBIR/Lega_lab/shared/lega_ansir/Pranish_Micro_AR/test/%s/sorted/%s',subj,sessDir);

cd(spikeDir);
T = dir2('*');

shortSegmentsInMin = 7;% EDIT THIS FOR LONGER/SHORTER SEGMENTS
sr = 30000;

for z = 1:length(T)
    if isfolder(T(z).name) && length(T(z).name) == 6 % Store all NS6 data in a folder called RawDir (= 6 characters)
        
        cd(T(z).name)
        T(z).name
        T1 = dir2(['NS6_0*' 'mat']);% change this line NS3_0* if you need to and also line 56
        % make sure you dont include channel 129
        %%%%%%%%%%% FIND OUT DURATION OF THE FILE %%%%%%%%%%%
        i =  1;
        temp = load(T1(i).name);
        names = fieldnames(temp);
        if length(names) == 1
            temp1 = double(temp.(names{1}));
            Data(i,:) = temp;
        elseif length(names) == 2
            temp1 = double(temp.(names{1}));
            sr = temp.(names{2});
            Data(i,:) = temp1;
        end
        
        disp('data duration in minutes')
        duration = size(Data,2)/(sr*60)
        timeVector = 0:1/sr:(duration*60)-(1/sr);
        numShortSegments = ceil(duration/shortSegmentsInMin);
        clear Data
        %%%%%%%%%%% GET SHORT SEGMENTS %%%%%%%%%%%
        for sk = 1:numShortSegments
            Data = [];
            % read each channel and take a segment of it and clean line
            % noise using coh-subtract method
            for i =  1:length(T1)
                [sk i]
                temp = load(T1(i).name);
                names = fieldnames(temp);
                if length(names) == 1
                    temp1 = double(temp.(names{1}));
                    idx = 1 + ((sk-1)*(60*sr*shortSegmentsInMin)) :  (sk*60*sr*shortSegmentsInMin);
                    if sk < numShortSegments
                        Data(i,:) = temp1(idx);
                    else
                        Data(i,:) = temp1(idx(1):end);
                        idx = idx(idx <= duration*60*sr);
                    end
                elseif length(names) == 2
                    temp1 = double(temp.(names{1}));
                    sr = temp.(names{2});
                    idx = 1 + ((sk-1)*(60*sr*shortSegmentsInMin)) :  (sk*60*sr*shortSegmentsInMin);
                    if sk < numShortSegments
                        Data(i,:) = temp1(idx);
                    else
                        Data(i,:) = temp1(idx(1):end);
                        idx = idx(idx <= duration*60*sr);
                    end
                end
            end
            timeVecInSeconds = timeVector(idx);
            disp('%%%%%%%%%% Processing data between these minutes %%%%%%')
            sprintf('%5.2f\t',([timeVecInSeconds(1) timeVecInSeconds(end)]/60))
            
%             keyboard
            %%%%%%%%%%%%%%%%%%%%%% COHERENCE SUBTRACT  %%%%%%%%%%%%%%%%%%%%
            if exist('Data', 'var')
                [numChan, numDtp] = size(Data);
                aveEEG = mean(Data,1);
                alpha1 = 0.001;
                numOneMinSegments = ceil(numDtp/(60*sr));% number of one minute segments
                
                if numOneMinSegments > 1
                    % filtered_data = zeros(numChan,numDtp);uncomment this
                    % if we need to combine all channels into one vector
                    for kk =  1 : numChan
                        kk
                        for k = 1 : numOneMinSegments
                            % consider one minute segment
                            ti = 1 + ((k-1)*(60*sr)) :  (k*60*sr);
                            % if data is less than one minute, consider one
                            % minute before the last time point
                            if ti(end) > numDtp
                                ti = numDtp - (60*sr) + 1 : numDtp;
                            end
                            % cleanEEG using coherence subtract method, first input has to be a
                            % reference signal
                            [z1 ]=coh_subtract(aveEEG(ti),Data(kk,ti),sr, 3*sr, alpha1);
                            data(1,ti) = z1';
                        end
                        % plot first one second data and save for reference
                        figure(1), clf,plot(Data(kk,1:sr)), hold on, plot(data( 1:sr),'r')
                        jpg_path = ['jpg_' datestr(date, 'yyyymmdd')];
                        if ~isfolder(jpg_path)
                            mkdir(jpg_path)
                        end
                        saveFigPath = fullfile(pwd, jpg_path);
                        saveFig = fullfile(saveFigPath, sprintf('/NS6_%03d_startTimeInMin%03d.jpg',kk,(sk-1)*shortSegmentsInMin));
                        saveas(gcf, saveFig) 
                        pause(.1)
                        
                        % save short segments for each chennal
                        savepath = ['clean_'  num2str(shortSegmentsInMin) 'MinSegments_' datestr(date, 'yyyymmdd')];
                        if ~isfolder(savepath)
                            mkdir(savepath)
                        end
                        savefile= sprintf('NS6_%03d_startTimeInMin%03d',kk,(sk-1)*shortSegmentsInMin);
                        % filtered_data(kk,:) =    data ; % uncomment this
                        % if we need to combine all channels into one
                        % vector
                        saveFileName = [T(z).folder '/' T(z).name '/' savepath '/' savefile]
                        save(saveFileName,'data','sr','timeVecInSeconds');
                        clear data
                    end
                    clear Data aveEEG
                end
            end
            
            %%%%%%%%%%%%%%%%%%%%%% END OF COHERENCE SUBTRACT  %%%%%%%%%%%%%%%%
        end
        close all
        clearvars -except z T T1 savepath sr
         %%%%%%%%%%%%%% COMBINE DATA FROM SHORT SEGMENTS  %%%%%%%%%%%%%%%%
        cd(savepath)
        for y = 1 : length(T1)
            % find how short segments for a particular channel
            T2 = dir([ T1(y).name(1:end-4) '*.mat']);
            Data = []; Time1 = [];
            % append all short segments for a particular channel
            for x = 1 : length(T2)
                T2(x).name
                load(T2(x).name)
                Data = [Data data];
                Time1 = [Time1 timeVecInSeconds];
            end
            % time should be in ascending order based on filenames but better to check
            [~, idx] = sort(Time1, 'ascend');
            if ~isempty(find(diff(idx) > 1, 1))
                error('some problem with idx, this would happen if there are more than 999 files for any channel')
            end
            % sort Data and time vectors based on time
            data = int16(Data(idx));
            timeVecInSeconds = Time1(idx);
            saveFolder = [T(z).folder '/' T(z).name '/clean_' datestr(date, 'yyyymmdd')];
            if ~isfolder(saveFolder)
                mkdir(saveFolder)
            end
            % save combined file for each channel individually
            saveFile = fullfile(saveFolder, [T1(y).name(1:end-4) '_clean.mat'])
            save(saveFile,'data','sr')
            
        end
        
        cd ..
         %%%%%%%%%%%%%% END OF COMBINE DATA FROM SHORT SEGMENTS  %%%%%%%%
        
       
        cd ..
         clearvars -except z T T1
    end
end
