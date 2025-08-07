

% CCF Tutorial
% Nick Steinmetz, 2025-08-07

% Topics:
% How it was generated, how the axes, labels, etc are defined
% A browser
% What the structure tree is and how to use it
% Example use case: extracting labels for given 3D positions
% Example use case: plotting/using a map of cortical regions
% Example use case: plotting a slice of the brain in a nice way
% Example use case: converting a 3D coordinate of cortex into a 2D flatmap coordinate plus depth
% Example use case: re-aggregating regions with beryl or cosmos
% Existing lab tools for CCF
% Future directions of CCF: further parcellations
% Future directions of CCF: stereotaxic corrections

%% Paths

addpath(genpath(fullfile(githubDir, 'npy-matlab'))) % kwikteam/npy-matlab
addpath(genpath(fullfile(githubDir, 'allenCCF')))

%% Loading

tv = readNPY('/Users/nicksteinmetz/data/ccf/template_volume_10um.npy');
av = readNPY('/Users/nicksteinmetz/data/ccf/annotation_volume_10um_by_index.npy');
st = loadStructureTree();

whos tv av % size 1320 x 800 x 1140, datatype uint16
% voxel size is 10 µm so that's 13.2 mm in the A->P direction, 8 mm in the
% D->V direction, and 11.4 mm in the L->R direction

%% Browser

figure; 

subplot(2,3,1);
imagesc(tv(:,:,500)'); % sagittal template volume, 5 mm from left face
axis image; colormap gray; caxis([0 400]);

subplot(2,3,2); 
imagesc(squeeze(tv(:,500,:))); %horizontal tv, 5 mm from top face
axis image; colormap gray; caxis([0 400]);

subplot(2,3,3); 
imagesc(squeeze(tv(500,:,:))); %horizontal tv, 5 mm from rostral face
axis image; colormap gray; caxis([0 400]);

% now same but for annotation volume
% can use a special colormap for this
cmap = allen_ccf_colormap('2017');
% cmap = parula(size(cmap,1));
            
ax = subplot(2,3,4);
imagesc(av(:,:,500)'); 
axis image; 
colormap(ax, cmap); caxis(ax, [1 size(cmap,1)]);

ax = subplot(2,3,5); 
imagesc(squeeze(av(:,500,:))); 
axis image; 
colormap(ax, cmap); caxis(ax, [1 size(cmap,1)]);

ax = subplot(2,3,6); 
imagesc(squeeze(av(500,:,:))); 
axis image; 
colormap(ax, cmap); caxis(ax, [1 size(cmap,1)]);


%% structure tree

st(1:10,:)

%% extracting labels for given 3D positions and slices

apCoord = 500; dvCoord = 440; lrCoord = 270; % is in caudoputamen

idx = av(apCoord, dvCoord, lrCoord)
thisAcr = st.acronym{idx}

idRegionByAcr(st, thisAcr)
% gives:
% Caudoputamen
% -Striatum dorsal region
% --Striatum
% ---Cerebral nuclei
% ----Cerebrum
% -----Basic cell groups and regions
% ------root


%% plotting a slice of the brain in a nice way

figure; 
[coords, coordsReg, h] = sliceOutlineWithRegionVec(squeeze(av(500,:,:)), idx, [0 0.4 0.8], gca);

arrayfun(@(x)set(h(x),'Color',[0.8 0.4 0]),1:numel(h))

%% plotting/using a map of cortical regions

pixSize = 0.015; % µm
bregma = [400 400]; lambda = [700 500];

figure;
addAllenCtxOutlines(bregma, lambda, 'k', pixSize)
set(gca, 'YDir', 'reverse')
axis image
hold on; plot(bregma(2), bregma(1), 'ro', 'MarkerFaceColor','r'); 
plot(lambda(2), lambda(1), 'bo', 'MarkerFaceColor','b'); 

%% converting a 3D coordinate of cortex into a 2D flatmap coordinate plus depth

% tbd, new tool from IBL

%% re-aggregating regions with beryl or cosmos

acrIn = {'VISp5', 'VISp6a', 'MB', 'VISpm1', 'MB', 'LP', 'VISp5', 'LGd', 'VISp'};
acrOut = aggregateAcr(acrIn);

%% tree representation 

tp = makeSTtree(st);
% [treePairsInd, treePairs] = makeSTtree(st)
% make structure tree into a list of parent/child relationships. This makes
% it very quick to find all indices that are a child of another, etc. 
%
% Use "loadStructureTree" to get the input argument
%
% output has three columns: parent, child, number of levels between
% e.g. [4 6 2] means that 4 is a grandparent of 6 (2 levels above)
%
% treePairs uses the "id"s of the structures, treePairsInd uses the
% indices, i.e. the row numbers.
%
% This makes several operations trivial, e.g.: 
% - Find all direct children of a certain structure:
targetID = find(strcmp(st.acronym,'VISp'));
ch = tp(tp(:,1)==targetID & tp(:,3)==1,2);
st.acronym(ch)

% - Find siblings of a certain structure:
%  >> parentID = tp(tp(:,2)==targetID & tp(:,3)==1,1);
%  >> sib = % as above, for children

% - Find all structures anywhere below a target:
targetID = find(strcmp(st.acronym,'SCm'));
below = tp(tp(:,1)==targetID,2);
st.acronym(below)


%% the 3d brain grid

figure; plotBrainGrid()

%% a 3D isosurface

avBin = double(av>1);
subFactor = 5;
avBinSub = avBin(1:subFactor:end,1:subFactor:end,1:subFactor:end);
figure;
fv = isosurface(avBinSub, 0.5);
p = patch(fv);
p.FaceColor = 'red';
% p.FaceAlpha = 0.5;
p.EdgeColor = 'none';
daspect([1 1 1])
view(3)
camlight; lighting phong
axis equal