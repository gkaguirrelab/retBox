function pRFs = makePRFmaps(params)

% Make pRF maps using 'pRF' function
%
%   Usage:
%       pRFs = makePRFmaps(params)
%
%   Required:
%       params.stimFile     - '/full/path/to/stimFile.mat'
%       params.inVol        - '/full/path/to/inVol.nii.gz'
%       params.outDir       - '/full/path/to/outDir'
%       params.baseName     - output base name (e.g. 'lh')
%
%   Outputs:
%       fullfile(outDir,[params.baseName '.ecc.nii.gz'])
%       fullfile(outDir,[params.baseName '.pol.nii.gz'])
%       fullfile(outDir,[params.baseName '.sig.nii.gz'])
%       fullfile(outDir,[params.baseName '.co.nii.gz'])
%
%   Written by Andrew S Bock Nov 2016

%% load the data
ims                     = load(params.stimFile);
params.stimData         = ims.params.stimParams.imagesFull;
tcs                     = load_nifti(params.inVol);
dims                    = size(tcs.vol);
if length(dims)>2
    tmpTcs              = reshape(tcs.vol,dims(1)*dims(2)*dims(3),dims(4));
    params.obsData      = tmpTcs;
else
    params.obsData      = tcs.vol;
end
%% calculate pRF maps
pRFs                    = pRF(params);

%% Save output maps
if ~exist(params.outDir,'dir')
    mkdir(params.outDir);
end
if length(dims)>2
    outEcc              = reshape(pRFs.ecc,dims(1),dims(2),dims(3));
    outPol              = reshape(pRFs.pol,dims(1),dims(2),dims(3));
    outSig              = reshape(pRFs.sig,dims(1),dims(2),dims(3));
    outCo               = reshape(pRFs.co,dims(1),dims(2),dims(3));
else
    outEcc              = pRFs.ecc;
    outPol              = pRFs.pol;
    outSig              = pRFs.sig;
    outCo               = pRFs.co;
end
outNii                  = tcs;
outNii.dim(5)           = 1;
% eccentricity
outNii.vol              = outEcc;
save_nifti(outNii,fullfile(params.outDir,[params.baseName '.ecc.nii.gz']));
% polar angle
outNii.vol              = outPol;
save_nifti(outNii,fullfile(params.outDir,[params.baseName '.pol.nii.gz']));
% sigma
outNii.vol              = outSig;
save_nifti(outNii,fullfile(params.outDir,[params.baseName '.sig.nii.gz']));
% correlation
outNii.vol              = outCo;
save_nifti(outNii,fullfile(params.outDir,[params.baseName '.co.nii.gz']));
