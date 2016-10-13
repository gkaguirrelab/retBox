%   This script provides example code to load data from an example TOME
%   subject, calculate population receptive fields, and visualize the
%   eccentricty and polar angle maps on the cortical surface.
%
%   Written by Andrew S Bock Oct 2016

%% set defaults
[~, tmpName]            = system('whoami');
userName                = strtrim(tmpName); % Get user name
dataDir                 = ['/Users/' userName '/Dropbox-Aguirre-Brainard-Lab/retData'];
sessionDir              = '/data/jag/TOME/TOME_3001/081916a';
anatTemplate            = fullfile(sessionDir,'anat_templates','lh.areas.anat.nii.gz');
subjectName             = 'TOME_3001';
%% load the data
tmp                     = load(fullfile(dataDir,'pRFimages.mat'));
params.stimData         = tmp.imagesFull;
tmp                     = load(fullfile(dataDir,'V1tc.mat'));
params.obsData          = tmp.V1tc;
%% Calculate pRFs
pRFs = pRF(params);

%% Get the indices (if not entire surface or volume)
a                       = load_nifti(anatTemplate);
V1ind                   = find(abs(a.vol)==1);
ecc                     = nan(size(a.vol));
pol                     = nan(size(a.vol));
co                      = nan(size(a.vol));
sig                     = nan(size(a.vol));
ecc(V1ind)              = pRFs.ecc;
pol(V1ind)              = pRFs.pol;
co(V1ind)               = pRFs.co; 
sig(V1ind)              = pRFs.sig;
%% Plot the pRFs
surface_plot('ecc',ecc,subjectName);
surface_plot('pol',pol,subjectName);
surface_plot('co',co,subjectName);
surface_plot('sig',sig,subjectName);