ccc;
%% set root directory & make sure raw data is on path
root_dir = dir2 ('/Users/Pranish/Desktop/FR1_Local_Data/Have_Events'); % have to use the custom function dir2 because of the presence of '.','..','.DS_Store'; make sure to check the output in case there is more #s
addpath(genpath('/Users/Pranish/Desktop/FR1_Local_Data')); % set this to the main data directory
%% Begin analysis
mu_cat_alpha = [];
mu_cat_beta = [];
mu_cat_gamma = [];
ul_cat_alpha = [];
ll_cat_alpha = [];
ul_cat_gamma = [];
ll_cat_gamma = [];
ul_cat_beta = [];
ll_cat_beta = [];

for subjdir = root_dir'
    
    current_dir = [subjdir.folder filesep subjdir.name];
    cd(current_dir)
    
    subject = subjdir.name;
    pos_analysis_files=dir2('Analysis_Encode/Pos/Significant');
    neg_analysis_files=dir2('Analysis_Encode/Neg/Significant');
    
    pos_analysis_files = pos_analysis_files(~[pos_analysis_files.isdir]);
    neg_analysis_files = neg_analysis_files(~[neg_analysis_files.isdir]);
    
    for pos_or_neg_analysis_files = [pos_analysis_files;neg_analysis_files]'
        
        load([pos_or_neg_analysis_files.folder filesep pos_or_neg_analysis_files.name]);
 
        
        S = [size(pval,1),size(pval,2)];
        
        
        
        for i = 1:size(frequency_sliding,1)
            tmp = ~isnan(frequency_sliding(i,:));
            tmp1 = frequency_sliding(i,:);
            frequency_nonan = tmp1(tmp);
            bands_centered(i,:) = mode(frequency_nonan);
        end
        
        for ii = 1:S(1) % ii is the index for the number of bands
            for jj = 1:S(2) % jj is the index for number of neurons
                
                if bands_centered(ii,:) >= 0 && bands_centered(ii,:) <= 7 && pval{ii,jj} <= 0.001
                    mu_cat_alpha = [mu_cat_alpha;mu{ii,jj}];
                    
                elseif bands_centered(ii,:) >= 18 && bands_centered(ii,:) <= 33 && pval{ii,jj} <= 0.001
                    
                    mu_cat_beta = [mu_cat_beta;mu{ii,jj}];
                    
                elseif bands_centered(ii,:) >= 45 && bands_centered(ii,:) <= 50 && pval{ii,jj} <= 0.001
                    
                    mu_cat_gamma = [mu_cat_gamma;mu{ii,jj}];
                    
                end
            end
        end
    end
end
circ_mean(mu_cat_alpha)
circ_mean(mu_cat_beta)
circ_mean(mu_cat_gamma)
% mu_alpha = 
% mu_beta = 
% mu_gamma = 
[pval_alpha, z_alpha] = circ_rtest(mu_cat_alpha);
[pval_beta, z_beta] = circ_rtest(mu_cat_beta);
[pval_gamma, z_gamma] = circ_rtest(mu_cat_gamma);
