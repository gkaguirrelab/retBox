%   This script provides example code to load data from an example TOME
%   subject, calculate population receptive fields, and visualize the
%   eccentricty and polar angle maps on the cortical surface.
%
%   Written by Andrew S Bock Oct 2016

%% set defaults
[~, tmpName]            = system('whoami');
userName                = strtrim(tmpName); % Get user name
dataDir                 = ['/Users/' userName '/Dropbox-Aguirre-Brainard-Lab/retData'];
fieldSize               = 19.6129; % radius of stimuluated visual field in degrees visual angle
padFactor               = 2; % how much padding outside of the stimulated visual field
subjectDist             = 106.5;
screenHgt               = 1080;
framesPerTR             = 8;
gridPoints              = 101;
sigList                 = 1;
TR                      = 0.8; % seconds
sessionDir              = '/data/jag/TOME/TOME_3001/081916b';
anatTemplate            = fullfile(sessionDir,'anat_templates','lh.areas.anat.nii.gz');
subjectName             = 'TOME_3001';
%% load the data
stimData                    = load(fullfile(dataDir,'pRFimages.mat'));
obsData                     = load(fullfile(dataDir,'V1tc.mat'));
%% Binarize the stimulus
stim                    = 0.*stimData.imagesFull;
oneImage                = stimData.imagesFull ~= 128; % not background
stim(oneImage)          = 1;

%% Average the frames within each TR
start                   = 1:framesPerTR:size(stim,3);
stop                    = start(2)-1:framesPerTR:size(stim,3);
meanImages              = nan(size(stim,1),size(stim,2),size(stim,3)/framesPerTR);
for i = 1:length(start)
    meanImages(:,:,i) = mean(stim(:,:,start(i):stop(i)),3);
end
%% Add black around stimulus region, to model the actual visual field (not just the bars)
padImages = padarray(meanImages,(padFactor/2)*[(screenHgt/2) (screenHgt/2)]);

%% Create X, Y, and sigma
%tmpgrid                 = -fieldSize:sampleRate:fieldSize;
tmpgrid                 = linspace(-fieldSize*padFactor,fieldSize*padFactor,gridPoints);
[x,y]                   = meshgrid(tmpgrid,tmpgrid);
tmpx0                   = x(:);
tmpy0                   = y(:);
X                       = x(:);
Y                       = y(:);
x0                      = repmat(tmpx0,size(sigList,1),1);
y0                      = repmat(tmpy0,size(sigList,1),1);
sigs                    = repmat(sigList,size(tmpx0,1),1);
%% resample images to sampling grid
nImages = size(padImages, 3);
images = zeros(gridPoints^2,nImages);
for ii = 1:nImages
    tmp_im = imresize(padImages(:,:,ii), [gridPoints gridPoints]);
    images(:, ii) = tmp_im(:);
end
%% Break up into smaller matrices
nn = numel(x0); % grid points
[predPerTask,predTasks] = calc_tasks(nn,ceil(nn/1000));
predidx = [];
for i = 1:predTasks
    if isempty(predidx);
        predidx = [1,predPerTask(i)];
    else
        predidx = [predidx;[predidx(end,2)+1,predidx(end,2)+predPerTask(i)]];
    end
    predvals{i} = predidx(i,1):predidx(i,2);
end
%% Make/load HRF
HRF = doubleGammaHrf(TR);
%% Make predicted timecoures from stimulus images
predTCs                 = nan(size(images))';
progBar                 = ProgressBar(length(predvals),'making predictions...');
for n=1:length(predvals)
    tSigs               = sigs(predvals{n},:);
    tx0                 = x0(predvals{n});
    ty0                 = y0(predvals{n});
    % Allow x, y, sigma to be a matrix so that the final output will be
    % size(X,1) by size(x0,2). This way we can make many RFs at the same time.
    if numel(tSigs)~=1,
        sz1             = size(X,1);
        sz2             = size(tSigs,1);
        tX              = repmat(X,1,sz2);
        tY              = repmat(Y(:),1,sz2);
        nx0             = repmat(tx0',sz1,1);
        ny0             = repmat(ty0',sz1,1);
        nSigs           = repmat(tSigs,1,1,sz1);
        nSigs           = permute(nSigs,[3 1 2]);
    end
    % Translate grid so that center is at RF center
    nX                  = tX - nx0;   % positive x0 moves center right
    nY                  = tY - ny0;   % positive y0 moves center up
    % make gaussian on current grid
    rf                  = exp (-(nY.^2 + nX.^2) ./ (2*nSigs(:,:,1).^2));
    % Convolve images with HRF
    imagesHRF           = filter(HRF,1, images');
    % Convolve images (with HRF) with Gaussian receptive field
    pred                = imagesHRF*rf;
    % Set timecourses with very little variation (var<0.1) to flat
    pred                = set_to_flat(pred);
    % store the predictions
    predTCs(:,predvals{n}) = pred;
    progBar(n);
end
%% Find pRFs
progBar                 = ProgressBar(size(obsData.V1tc,1),'calculating pRFs...');
pRFs.x0                 = nan(size(obsData.V1tc,1),1);
pRFs.y0                 = nan(size(obsData.V1tc,1),1);
pRFs.sig                = nan(size(obsData.V1tc,1),1);
pRFs.rVal               = nan(size(obsData.V1tc,1),1);
for i = 1:size(obsData.V1tc,1)
    pRFcorrs            = corr(obsData.V1tc(i,:)',predTCs);
    [rVal,bestInd]      = max(pRFcorrs);
    pRFs.x0(i)          = x0(bestInd);
    pRFs.y0(i)          = y0(bestInd);
    pRFs.sig(i)         = sigs(bestInd);
    pRFs.rVal(i)        = rVal;
    if ~mod(i,100);progBar(i);end
end
[pRFs.pol,pRFs.ecc] = cart2pol(pRFs.x0,pRFs.y0);
%% Plot pRFs
a                       = load_nifti(anatTemplate);
V1ind                   = find(abs(a.vol)==1);
ecc                     = nan(size(a.vol));
pol                     = nan(size(a.vol));
ecc(V1ind)              = pRFs.ecc;
pol(V1ind)              = pRFs.pol;
surface_plot('ecc',ecc,subjectName);
surface_plot('pol',pol,subjectName);