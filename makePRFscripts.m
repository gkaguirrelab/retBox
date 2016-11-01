function makePRFscripts(params)

% Creates shell scripts to create pRF maps using 'makePRFmaps'
%
%   Usage:
%       makePRFscripts(params)
%
%   Required:
%       params.scriptDir    - '/full/path/to/scriptDir'
%       params.jobName      - 'jobName.sh'
%       params.submitName   - 'submit_jobName.sh'
%       params.stimFile     - '/full/path/to/stimFile.mat'
%       params.inVol        - '/full/path/to/inVol.nii.gz'
%       params.outDir       - '/full/path/to/outDir'
%       params.outBase      - 'baseName' (e.g. 'lh');
%
%   Defaults:
%       params.mem          - 40; % GB of memory requested
%
%   Optional:
%       params.sigList      - vector of sigma sizes (e.g. 0.5:0.1:10);
%
%   Outputs:
%       fullfile(params.scriptDir,params.jobName)
%           shell script to call 'makePRFmaps'
%
%       fullfile(params.scriptDir,params.submitName)
%           shell script to submit the script above 
%
%   Written by Andrew S Bock Nov 2016

%% Set defaults
if ~exist(params,'mem')
    params.mem  = 40;
end
%% Set initial parameters
jName           = fullfile(params.scriptDir,params.jobName);
fid             = fopen(jName,'w');
fprintf(fid,'#!/bin/bash\n');
%% Make matlab string
matlab_string = '"';
matlab_string = [matlab_string 'params.stimFile=''' params.stimFile ''';' ...
    'params.inVol=''' params.inVol ''';params.outDir=''' params.outDir ''';' ...
    'params.baseName=''' params.baseName ''';'];
if isfield(params,'sigList')
    matlab_string   = [matlab_string 'params.sigList=[' num2str(params.sigList) '];'];
end
matlab_string   = [matlab_string 'makePRFmaps(params);'];
fprintf(fid,['matlab -nodisplay -nosplash -r ' matlab_string '"']);
fclose(fid);
%% Make submit script
sName           = fullfile(params.scriptDir,params.submitName);
fid             = fopen(sName,'w');
fprintf(fid,['qsub -l h_vmem=' num2str(params.fmem) ...
    '.2G,s_vmem=' num2str(params.fmem) 'G -e ' params.logDir ...
    ' -o ' params.logDir ' ' jName]);
fclose(fid);