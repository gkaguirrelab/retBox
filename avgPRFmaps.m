function avgPRFmaps(params)

% Saves average pRF maps using those created by the 'makePRFmaps' function
%
%   Usage:
%       avgPRFmaps(params)
%
%   Required:
%       params.sessionDir       - '/full/path/to/sessionDir'
%       params.baseName         - base name of files (e.g. 'lh')
%
%   Defaults:
%       params.outDir           - fullfile(params.sessionDir,'pRFmaps');
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
if ~isfield(params,'outDir');
    params.outDir   = fullfile(params.sessionDir,'pRFmaps');
end
if ~exist(params.outDir,'dir')
    mkdir(params.outDir);
end
%% load the data
d = listdir(fullfile(params.sessionDir,'*tfMRI_RETINO*'),'dirs');
for i = 1:length(d)
    thisDir         = fullfile(params.sessionDir,d{i});
    % load the data
    inEcc           = load_nifti(fullfile(thisDir,[params.baseName '.ecc.nii.gz']));
    inPol           = load_nifti(fullfile(thisDir,[params.baseName '.pol.nii.gz']));
    inSig           = load_nifti(fullfile(thisDir,[params.baseName '.sig.nii.gz']));
    inCo            = load_nifti(fullfile(thisDir,[params.baseName '.co.nii.gz']));
    % add to matrix
    ecc(i,:)        = inEcc.vol(:);
    pol(i,:)        = inPol.vol(:);
    sig(i,:)        = inSig.vol(:);
    co(i,:)         = inCo.vol(:);
end
%% Save out the average maps
% calculate mean
avgEcc              = mean(ecc);
avgPol              = circ_mean(pol);
avgSig              = mean(sig);
avgCo               = mean(fisher_z_corr(co));
% save maps
inEcc.vol           = avgEcc';
save_nifti(inEcc,fullfile(params.outDir,[params.baseName '.ecc.nii.gz']));
inPol.vol           = avgPol';
save_nifti(inPol,fullfile(params.outDir,[params.baseName '.pol.nii.gz']));
inSig.vol           = avgSig';
save_nifti(inSig,fullfile(params.outDir,[params.baseName '.sig.nii.gz']));
inCo.vol            = avgCo';
save_nifti(inCo,fullfile(params.outDir,[params.baseName '.co.nii.gz']));