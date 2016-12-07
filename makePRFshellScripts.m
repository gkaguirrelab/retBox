function makePRFshellScripts(params)

% Make the job and submit scripts to run pRF analysis on the UPenn cluster
%
%   Usage:
%       makePRFshellScripts(params)
%
%   Required:
%       params.sessionDir       = '/path/to/sessionDir';
%       params.logDir           = '/path/to/logDir';
%
%   Defaults:
%       params.scriptDir        = fullfile(params.sessionDir,'pRF_scripts');
%       params.outDir           = fullfile(params.sessionDir,'pRFs');
%
%   To run the scripts (from terminal on UPenn cluster):
%       sh /path/to/sessionDir/pRF_scripts/submitPRFs.sh
%
%   Written by Andrew S Bock Dec 2016

%% Set defaults
hemis                   = {'lh','rh'};
params.submitName       = 'submitPRFs.sh';
% script directory
if ~isfield(params,'scriptDir')
    params.scriptDir    = fullfile(params.sessionDir,'pRF_scripts');
end
system(['rm -rf ' params.scriptDir]);
mkdir(params.scriptDir);
% output directory for pRF data
if ~isfield(params,'outDir')
    params.outDir       = fullfile(params.sessionDir,'pRFs');
end
%% Get the retinotopy runs and stimulus files
b                       = listdir(fullfile(params.sessionDir,'*RETINO*'),'dirs');
stimFiles               = listdir(fullfile(params.sessionDir,'Stimuli','*RETINO*'),'files');
%% Make the scripts
for i = 1:length(b)
    for hh = 1:length(hemis)
        params.jobName  = sprintf([hemis{hh} '.run%02d.sh'],i);
        thisStim        = find(~cellfun('isempty',strfind(stimFiles,sprintf('run%02d',i))));
        params.stimFile = fullfile(params.sessionDir,'Stimuli',stimFiles{thisStim});
        params.inVol    = fullfile(params.sessionDir,b{i},['wdrf.tf.surf.' hemis{hh} '.nii.gz']);
        params.baseName = sprintf([hemis{hh} '.run%02d'],i);
        makePRFscripts(params)
    end
end
makePRFsubmit(params);