function pRFs = pRF(params)

%   Calculates population receptive fields
%
%   Usage:
%       pRFs = pRF(params)
%
%   Required:
%       params.stimData     - X x Y x frame matrix of stimulus images
%       params.obsData      - N x TR matrix of fMRI time-series data
%
%   Defaults:
%       params.fieldSize    = 10.4346;                      % Radius of stimuluated visual field (degrees visual angle)
%       params.padFactor    = 0.25;                         % Proportion of image to use as padding outside of the stimulated visual field
%       params.framesPerTR  = 8;                            % Frames per TR
%       params.gridPoints   = 101;                          % Search grid points
%       params.sigList      = 0.5:0.5:10;                   % List of sigma values (degrees visual angle)
%       params.TR           = 0.8;                          % TR
%       params.HRF          = doubleGammaHrf(params.TR);    % HRF
%       params.useVA        = 0;                            % use visual angle
%
%   Outputs:
%       pRF.x0              - x position
%       pRF.y0              - y position
%       pRF.sig             - sigma value
%       pRF.co              - correlation (calculated during fit)
%       pRF.pol             - polar angle
%       pRF.ecc             - eccentricity
%
%   Written by Andrew S Bock Oct 2016

%% set defaults
% Radius of stimuluated visual field (degrees visual angle)
if ~isfield(params,'fieldSize')
    params.fieldSize    = 10.4346;
end
% Padding outside of the stimulated visual field
if ~isfield(params,'padFactor')
    params.padFactor    = 0.25;
end
% Frames per TR
if ~isfield(params,'framesPerTR')
    params.framesPerTR  = 8;
end
% Search grid points
if ~isfield(params,'gridPoints')
    params.gridPoints   = 101;
end
% List of sigma values (degrees visual angle)
if ~isfield(params,'sigList')
    params.sigList      = 0.5:0.5:10;
end
% TR
if ~isfield(params,'TR')
    params.TR           = 0.8;
end
% HRF
if ~isfield(params,'HRF')
    params.HRF          = doubleGammaHrf(params.TR);
end
% use visual angle
if ~isfield(params,'useVA')
    params.useVA        = 0;
end
%% Binarize the stimulus
disp('Binarizing the stimulus images...');
stim                    = 0.*params.stimData;
oneImage                = params.stimData ~= 128; % not background
stim(oneImage)          = 1;
%% Average the frames within each TR
disp('Calculating the mean image per TR...');
start                   = 1:params.framesPerTR:size(stim,3);
stop                    = start(2)-1:params.framesPerTR:size(stim,3);
meanImages              = nan(size(stim,1),size(stim,2),size(stim,3)/params.framesPerTR);
for i = 1:length(start)
    meanImages(:,:,i) = mean(stim(:,:,start(i):stop(i)),3);
end
%% Calculate the visual angle, update images
if params.useVA
    [vX,vY] = calcScreenVisualAngle(params);
    [Xq,Yq] = meshgrid(...
        linspace(min(vX(:)),max(vX(:)),length(vX)),...
        linspace(min(vY(:)),max(vY(:)),length(vY)));
    nImages = size(meanImages, 3);
    for ii = 1:nImages
        V = squeeze(meanImages(:,:,ii));
        meanImages(:,:,ii) = interp2(vX,vY,V,Xq,Yq);
    end
end
%% Add black around stimulus region, to model the actual visual field (not just the bars)
disp('Padding the stimulus images...');
padImages = padarray(meanImages,(params.padFactor/2)*[size(meanImages,1) size(meanImages,2)]);

%% Create X, Y, and sigma
tmpgrid                 = linspace(-params.fieldSize - (params.fieldSize*params.padFactor),...
    params.fieldSize + (params.fieldSize*params.padFactor),params.gridPoints);
[x,y]                   = meshgrid(tmpgrid,tmpgrid);
tmpx0                   = x(:);
tmpy0                   = y(:);
X                       = x(:);
Y                       = y(:);
x0                      = repmat(tmpx0,size(params.sigList,2),1);
y0                      = repmat(tmpy0,size(params.sigList,2),1);
sigs                    = repmat(params.sigList,1,size(tmpx0,1))';
%% resample images to sampling grid
disp('Resampling images to search grid...')
nImages = size(padImages, 3);
images = zeros(params.gridPoints^2,nImages);
for ii = 1:nImages
    tmp_im = imresize(padImages(:,:,ii), [params.gridPoints params.gridPoints]);
    images(:, ii) = tmp_im(:);
end
%% Break up the prediction loop into small chunks
nn = numel(x0); % grid points
ind = break_up_matrix(nn,1000);
%% Make predicted timecoures from stimulus images
predTCs                 = nan(size(images))';
progBar                 = ProgressBar(length(ind),'making predictions...');
for n=1:length(ind)
    tSigs               = sigs(ind{n},:);
    tx0                 = x0(ind{n});
    ty0                 = y0(ind{n});
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
    imagesHRF           = filter(params.HRF,1, images');
    % Convolve images (with HRF) with Gaussian receptive field
    pred                = imagesHRF*rf;
    % Set timecourses with very little variation (var<0.1) to flat
    pred                = set_to_flat(pred);
    % store the predictions
    predTCs(:,ind{n}) = pred;
    progBar(n);
end
%% Break up the observation loop into small chunks
nn = size(params.obsData,1); % number of voxels/vertices
ind = break_up_matrix(nn,500);
%% Find pRFs
progBar                 = ProgressBar(length(ind),'calculating pRFs...');
pRFs.x0                 = nan(size(params.obsData,1),1);
pRFs.y0                 = nan(size(params.obsData,1),1);
pRFs.sig                = nan(size(params.obsData,1),1);
pRFs.co                 = nan(size(params.obsData,1),1);
for i = 1:length(ind)
        pRFcorrs            = corr(params.obsData(ind{i},:)',predTCs);
        [co,bestInd]        = max(pRFcorrs,[],2);
        pRFs.x0(ind{i})    = x0(bestInd);
        pRFs.y0(ind{i})    = y0(bestInd);
        pRFs.sig(ind{i})   = sigs(bestInd);
        pRFs.co(ind{i})    = co;
    if ~mod(i,10);progBar(i);end
end
[pRFs.pol,pRFs.ecc] = cart2pol(pRFs.x0,pRFs.y0);