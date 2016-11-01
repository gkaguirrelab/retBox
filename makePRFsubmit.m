function makePRFsubmit(params)

% Creates shell script to submit pRF scripts made by 'makePRFscripts'
%
%   Usage:
%       makePRFsubmit(params)
%
%   Required:
%       params.scriptDir    - '/full/path/to/scriptDir'
%       params.submitName   - 'submit_jobName.sh'
%       params.logDir       - '/full/path/to/logDir'
%
%   Defaults:
%       params.mem          - 40; % GB of memory requested
%
%   Outputs:
%       fullfile(params.scriptDir,params.submitName)
%           shell script to submit the pRF job scripts
%
%   Written by Andrew S Bock Nov 2016

%% Set defaults
if ~isfield(params,'mem')
    params.mem  = 40;
end
%% Set initial parameters
if ~exist(params.scriptDir,'dir')
    mkdir(params.scriptDir);
end
sName           = fullfile(params.scriptDir,params.submitName);
fid             = fopen(sName,'w');
fprintf(fid,'#!/bin/bash\n');
%% Make submit script
jobNames = listdir(fullfile(params.scriptDir,'*.sh'),'files');
for i = 1:length(jobNames)
    jName = fullfile(params.scriptDir,jobNames{i});
    fprintf(fid,['qsub -l h_vmem=' num2str(params.mem) ...
        '.2G,s_vmem=' num2str(params.mem) 'G -e ' params.logDir ...
        ' -o ' params.logDir ' ' jName '\n']);
end
fclose(fid);