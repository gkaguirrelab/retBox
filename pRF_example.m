%   This script provides example code to load data from an example TOME
%   subject, calculate population receptive fields, and visualize the
%   eccentricty and polar angle maps on the cortical surface.
%
%   Written by Andrew S Bock Oct 2016

%% Set inputs
subjectName             = 'TOME_3001';
sessionDir              = '/data/jag/TOME/TOME_3001/081916b';
b                       = find_bold(sessionDir);
runNum                  = 1;
matName                 = 'tfMRI_RETINO_PA_run01.mat';
func                    = 'wdrf.tf.surf.lh';
inVol                   = fullfile(sessionDir,b{runNum},[func '.nii.gz']);
inImages                = fullfile(sessionDir,'Stimuli',matName);
%% load the data
ims                     = load(inImages);
params.stimData         = ims.params.stimParams.imagesFull;
tcs                     = load_nifti(inVol);
dims                    = size(tcs.vol);
if length(dims)>2
    tmpTcs              = reshape(tcs.vol,dims(1)*dims(2)*dims(3),dims(4));
    params.obsData          = tmpTcs;
else
    params.obsData          = tcs.vol;
end
%% Calculate pRFs
pRFs = pRF(params);

%% Plot the pRFs
% Threshold by fit
goodInd                 = pRFs.co>=sqrt(0.05);
ecc                     = pRFs.ecc;
pol                     = pRFs.pol;
co                      = pRFs.co;
sig                     = pRFs.sig;
ecc(~goodInd)           = nan;
pol(~goodInd)           = nan;
co(~goodInd)            = nan;
sig(~goodInd)           = nan;
% Make plots
surface_plot('ecc',ecc,subjectName);
surface_plot('pol',pol,subjectName);
surface_plot('co',co,subjectName);
surface_plot('sig',sig,subjectName);