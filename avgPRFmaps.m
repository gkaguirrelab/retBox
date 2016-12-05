function avgPRFmaps(params)

% Saves average pRF maps using those created by the 'makePRFmaps' function
%
%   Usage:
%       avgPRFmaps(params)
%
%   Required:
%       params.inDir            = '/full/path/to/inputDir'
%       params.outDir           = '/full/path/to/outputDir'
%       params.baseName         = base name of files (e.g. 'lh')
%
%   Outputs:
%       fullfile(outDir,[params.baseName '.ecc.nii.gz'])
%       fullfile(outDir,[params.baseName '.pol.nii.gz'])
%       fullfile(outDir,[params.baseName '.sig.nii.gz'])
%       fullfile(outDir,[params.baseName '.co.nii.gz'])
%
%   Notes on how the mean is calculate for each map:
%       avgEcc                  - mean(ecc);
%       avgPol                  - circ_mean(pol);
%       avgSig                  - mean(sig);
%       avgCo                   - mean(fisher_z_corr(co));
%
%   Written by Andrew S Bock Nov 2016

%% Set defaults
if ~exist(params.outDir,'dir')
    mkdir(params.outDir);
end
mapNames            = {'ecc','pol','sig','co'};
%% load the data
for i = 1:length(mapNames)
    f                   = listdir(fullfile(params.inDir,[params.baseName '*' mapNames{i} '*']),'files');
    for j = 1:length(f)
        thisFile        = load_nifti(fullfile(params.inDir,f{j}));
        % add to matrix
        switch mapNames{i}
            case 'ecc'
                ecc(j,:)        = thisFile.vol(:);
            case 'pol'
                pol(j,:)        = thisFile.vol(:);
            case 'sig'
                sig(j,:)        = thisFile.vol(:);
            case 'co'
                co(j,:)         = thisFile.vol(:);
        end
    end
end
%% Save out the average maps
% calculate mean
avgEcc              = mean(ecc);
avgPol              = circ_mean(pol);
avgSig              = mean(sig);
avgCo               = mean(fisher_z_corr(co));
% save maps
thisFile.vol           = avgEcc';
save_nifti(thisFile,fullfile(params.outDir,[params.baseName '.ecc.nii.gz']));
thisFile.vol           = avgPol';
save_nifti(thisFile,fullfile(params.outDir,[params.baseName '.pol.nii.gz']));
thisFile.vol           = avgSig';
save_nifti(thisFile,fullfile(params.outDir,[params.baseName '.sig.nii.gz']));
thisFile.vol            = avgCo';
save_nifti(thisFile,fullfile(params.outDir,[params.baseName '.co.nii.gz']));