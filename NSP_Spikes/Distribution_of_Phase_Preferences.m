% ccc;
% %% set root directory & make sure raw data is on path
% root_dir = dir2 ('/Volumes/Pranish/FR1_Local_Data/Current'); % have to use the custom function dir2 because of the presence of '.','..','.DS_Store'; make sure to check the output in case there is more #s
% addpath(genpath('/Volumes/Pranish/FR1_Local_Data')); % set this to the main data directory
% %% Begin analysis for encoding
% 
% phases_cat_low_theta_encode = [];
% phases_cat_high_theta_encode = [];
% phases_cat_beta_encode = [];
% phases_cat_gamma_encode = [];
% 
% for subjdir = root_dir'
%     
%     if subjdir.name == "Current"
%         continue
%     end
%     
%     current_dir = [subjdir.folder filesep subjdir.name];
%     cd(current_dir)
%     
%     subject = subjdir.name;
%     pos_analysis_files=dir2('Analysis_Encode/Pos/Significant');
%     neg_analysis_files=dir2('Analysis_Encode/Neg/Significant');
%     
%     pos_analysis_files = pos_analysis_files(~[pos_analysis_files.isdir]);
%     neg_analysis_files = neg_analysis_files(~[neg_analysis_files.isdir]);
%     
%     for pos_or_neg_analysis_files = [pos_analysis_files;neg_analysis_files]'
%         
%         load([pos_or_neg_analysis_files.folder filesep pos_or_neg_analysis_files.name]);
%         
%         S = [size(pval,1),size(pval,2)];
%         
%         
%         
%         for i = 1:size(frequency_sliding,1)
%             tmp = ~isnan(frequency_sliding(i,:));
%             tmp1 = frequency_sliding(i,:);
%             frequency_nonan = tmp1(tmp);
%             bands_centered(i,:) = mode(frequency_nonan);
%         end
%         
%         for ii = 1:S(1) % ii is the index for the number of bands
%             for jj = 1:S(2) % jj is the index for number of neurons
%                 
%                 if bands_centered(ii,:) >= 0.5 && bands_centered(ii,:) <= 4 && pval{ii,jj} <= 0.001
%                     phases_cat_low_theta_encode = [phases_cat_low_theta_encode,phases{ii,jj}];
%                     
%                 elseif bands_centered(ii,:) >= 5 && bands_centered(ii,:) <= 8 && pval{ii,jj} <= 0.001
%                     
%                     phases_cat_high_theta_encode = [phases_cat_high_theta_encode,phases{ii,jj}];
%                     
%                 elseif bands_centered(ii,:) >= 18 && bands_centered(ii,:) <= 30 && pval{ii,jj} <= 0.001
%                     
%                     phases_cat_beta_encode = [phases_cat_beta_encode,phases{ii,jj}];
%                     
%                 elseif bands_centered(ii,:) >= 40 && bands_centered(ii,:) <= 50 && pval{ii,jj} <= 0.001
%                     
%                     phases_cat_gamma_encode = [phases_cat_gamma_encode,phases{ii,jj}];
%                     
%                 end
%             end
%         end
%     end
%     
% end
% 
% clearvars -except phases_cat_low_theta_encode phases_cat_high_theta_encode phases_cat_beta_encode phases_cat_gamma_encode root_dir
% %% Begin analysis for retrieval files
% 
% phases_cat_low_theta_retrieval = [];
% phases_cat_high_theta_retrieval = [];
% phases_cat_beta_retrieval = [];
% phases_cat_gamma_retrieval = [];
% 
% for subjdir = root_dir'
%     
%     if subjdir.name == "Current"
%         continue
%     end
%     
%     current_dir = [subjdir.folder filesep subjdir.name];
%     cd(current_dir)
%     
%     subject = subjdir.name;
%     pos_analysis_files=dir2('Analysis_Retrieval/Pos/Significant');
%     neg_analysis_files=dir2('Analysis_Retrieval/Neg/Significant');
%     
%     pos_analysis_files = pos_analysis_files(~[pos_analysis_files.isdir]);
%     neg_analysis_files = neg_analysis_files(~[neg_analysis_files.isdir]);
%     
%     for pos_or_neg_analysis_files = [pos_analysis_files;neg_analysis_files]'
%         
%         load([pos_or_neg_analysis_files.folder filesep pos_or_neg_analysis_files.name]);
%         
%         
%         S = [size(pval,1),size(pval,2)];
%         
%         
%         
%         for i = 1:size(frequency_sliding,1)
%             tmp = ~isnan(frequency_sliding(i,:));
%             tmp1 = frequency_sliding(i,:);
%             frequency_nonan = tmp1(tmp);
%             bands_centered(i,:) = mode(frequency_nonan);
%         end
%         
%         for ii = 1:S(1) % ii is the index for the number of bands
%             for jj = 1:S(2) % jj is the index for number of neurons
%                 
%                 if bands_centered(ii,:) >= 0.5 && bands_centered(ii,:) <= 4 && pval{ii,jj} <= 0.001
%                     phases_cat_low_theta_retrieval = [phases_cat_low_theta_retrieval,phases{ii,jj}];
%                     
%                 elseif bands_centered(ii,:) >= 5 && bands_centered(ii,:) <= 8 && pval{ii,jj} <= 0.001
%                     
%                     phases_cat_high_theta_retrieval = [phases_cat_high_theta_retrieval,phases{ii,jj}];
%                     
%                 elseif bands_centered(ii,:) >= 18 && bands_centered(ii,:) <= 30 && pval{ii,jj} <= 0.001
%                     
%                     phases_cat_beta_retrieval = [phases_cat_beta_retrieval,phases{ii,jj}];
%                     
%                 elseif bands_centered(ii,:) >= 40 && bands_centered(ii,:) <= 50 && pval{ii,jj} <= 0.001
%                     
%                     phases_cat_gamma_retrieval = [phases_cat_gamma_retrieval,phases{ii,jj}];
%                     
%                 end
%             end
%         end
%     end
%     
% end

z_gamma_encode = zscore(phases_cat_gamma_encode);
z_gamma_retrieval = zscore(phases_cat_gamma_retrieval);
[h,p] = ttest2(phases_cat_gamma_encode,phases_cat_beta_encode);

size_gamma_encode = length(phases_cat_gamma_encode);
nan_matrix = nan(1,size_gamma_encode);
test = phases_cat_gamma_encode;
test1 = phases_cat_gamma_retrieval;
nan_matrix(1,1:length(test)) = test;
nan_matrix(1:length(test1),1) = test1;

test_phases = [3.0450201,1.0419048,1.3106276,1.8399291,1.2425375,0.84542048,1.5562834,1.2448419,-0.52255321,1.8093487,-2.5947032,0.51531810,2.4032454,-1.2020249,NaN,NaN,NaN];
test_phases1 = [-0.10812073,0.84794670,-0.76644993,-1.2718087,1.4499447,2.9953802,0.84828115,2.0062740,-0.28383088,-0.45634380,-1.0037563,-1.4764090,-1.0145619,-2.1601493,NaN,NaN,NaN];

[rho_low_theta,pval_low_theta] = circ_corrcc(test_phases, test_phases1);


[rho_low_theta,pval_low_theta] = circ_corrcc(phases_cat_low_theta_encode, phases_cat_low_theta_retrieval);
[rho_high_theta,pval_high_theta] = circ_corrcc(phases_cat_high_theta_encode, phases_cat_high_theta_encode);
[rho_beta,pval_beta] = circ_corrcc(phases_cat_beta_encode, phases_cat_beta_retrieval);

[rho_gamma,pval_gamma] = circ_corrcc(phases_cat_gamma_encode, phases_cat_gamma_retrieval);




[rho_gamma_encode_lowtheta_retrieval,pval_gamma_encode_lowtheta_retrieval] = circ_corrcc(phases_cat_gamma_encode, phases_cat_low_theta_retrieval);
polarhistogram(phases_cat_beta_encode,19);



nan_matrix = nan(5000,13);
nan_matrix(1:length(FirstVariable), 1) = FirstVariable;
nan_matrix(1:length(SecondVariable), 2) = SecondVariable;



