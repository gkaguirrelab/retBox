function makePRFscripts(params)

% Creates shell scripts to create pRF maps using 'makePRFmaps'
%
%   Usage:
%       makePRFscripts(params)
%
%   Required:
%       params.scriptDir    - '/full/path/to/scriptDir'
%       params.jobName      - 'jobName.sh'
%       params.stimFile     - '/full/path/to/stimFile.mat'
%       params.inVol        - '/full/path/to/inVol.nii.gz'
%       params.outDir       - '/full/path/to/outDir'
%       params.outBase      - output base name (e.g. 'lh');
%
%   Optional:
%       params.sigList      - vector of sigma sizes (e.g. 0.5:0.1:10);
%
%   Outputs:
%       fullfile(params.scriptDir,params.jobName) 
%           shell script to call 'makePRFmaps'
%
%   Written by Andrew S Bock Nov 2016

%% Set initial parameters
if ~exist(params.scriptDir,'dir')
    mkdir(params.scriptDir);
end
jName           = fullfile(params.scriptDir,params.jobName);
fid             = fopen(jName,'w');
fprintf(fid,'#!/bin/bash\n');
%% Make matlab string
matlab_string = '"';
matlab_string = [matlab_string 'params.stimFile=''' params.stimFile ''';' ...
    'params.inVol=''' params.inVol ''';params.outDir=''' params.outDir ''';' ...
    'params.outBase=''' params.outBase ''';'];
if isfield(params,'sigList')
    matlab_string   = [matlab_string 'params.sigList=[' num2str(params.sigList) '];'];
end
matlab_string   = [matlab_string 'makePRFmaps(params);'];
fprintf(fid,['matlab -nodisplay -nosplash -r ' matlab_string '"']);
fclose(fid);