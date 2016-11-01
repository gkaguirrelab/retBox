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
params.inVol            = fullfile(sessionDir,b{runNum},[func '.nii.gz']);
params.stimFile         = fullfile(sessionDir,'Stimuli',matName);
params.outDir           = fullfile(sessionDir,'pRFs');
params.baseName         = 'lh';

%% Calculate pRFs, save maps
pRFs                    = makePRFmaps(params);

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
% Visualize maps
surface_plot('ecc',ecc,subjectName);
surface_plot('pol',pol,subjectName);
surface_plot('co',co,subjectName);
surface_plot('sig',sig,subjectName);