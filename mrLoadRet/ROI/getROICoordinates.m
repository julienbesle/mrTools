% getROICoordinates.m
%
%      usage: scanCoords = getROICoordinates(view,roiNum,<scanNum>,<groupNum>)
%         by: justin gardner
%       date: 04/02/07
%    purpose: get roi coordinates in scan coordinates
%             if scanNum is 0, then will compute in the current base
%             coordinates. 
%             if roinum is a structure, works on the structure
%             rather than the roinum
%             if roinum is a string, will load the roi from
%             the directory
function scanCoords = getROICoordinates(view,roiNum,scanNum,groupNum)

scanCoords = [];
% check arguments
if ~any(nargin == [2 3 4])
  help getROICoordinates
  return
end

% get group and scan
if ieNotDefined('groupNum')
  groupNum = viewGet(view,'currentGroup');
end
if ieNotDefined('scanNum')
  scanNum = viewGet(view,'currentScan');
end

% if roiNum is a string see if it is loaded, otherwise
% try to load it
nROIs = viewGet(view,'numROIs');
if isstr(roiNum)
  if isempty(viewGet(view,'roiNum',roiNum))
    % roi is not loaded in. get it
    view = loadROI(view,roiNum);
    roiNum = viewGet(view,'nROIs');
    if roiNum == nROIs
      disp(sprintf('(getROICoordinates) Could not load ROI'));
      return
    end
  else
    % roi is already installed, just get it
    roiNum = viewGet(view,'roiNum',roiNum);
  end
% if it is a struct use newRoi to set it into the view
elseif isstruct(roiNum)
  [tf roiNum] = isroi(roiNum); 
  if ~tf
    disp(sprintf('(getROICoordinates) Invalid ROI passed in'));
    return
  end
  currentROI = viewGet(view,'currentROI');
  view = viewSet(view,'newROI',roiNum,1);
  roiNum = viewGet(view,'ROINum',roiNum.name);
  view = viewSet(view,'currentROI',currentROI);
end

% get the roi transforms
roiVoxelSize = viewGet(view,'roiVoxelSize',roiNum);
roiCoords = viewGet(view,'roiCoords',roiNum);

% make sure we have normalized coordinates
if (size(roiCoords,1)==3)
  roiCoords(4,:) = 1;
end

% get the scan transforms
if scanNum
  scan2roi = viewGet(view,'scan2roi',roiNum,scanNum,groupNum);
  scanVoxelSize = viewGet(view,'scanVoxelSize',scanNum,groupNum);
else
  % use base xform if scanNum == 0
  view = viewSet(view,'curGroup',groupNum);
  scan2roi = viewGet(view,'base2roi',roiNum);
  scanVoxelSize = viewGet(view,'baseVoxelSize');
end  

if (isempty(scan2roi)) 
  disp(sprintf('(getRoiCoordinates) No xform available'));
  return
end

% Use xformROI to supersample the coordinates
scanCoords = round(xformROIcoords(roiCoords,inv(scan2roi),roiVoxelSize,scanVoxelSize));

% return the unique ones
if ~isempty(scanCoords)
  scanCoords = unique(scanCoords','rows')';
  scanCoords = scanCoords(1:3,:);
end

if ~isempty(scanCoords) && (scanNum ~= 0)

  % check scan dimensions
  scanDims = viewGet(view,'dims',scanNum,groupNum);

  % make sure we are inside scan dimensions
  xCheck = (scanCoords(1,:) >= 1) & (scanCoords(1,:) <= scanDims(1));
  yCheck = (scanCoords(2,:) >= 1) & (scanCoords(2,:) <= scanDims(2));
  sCheck = (scanCoords(3,:) >= 1) & (scanCoords(3,:) <= scanDims(3));

  % only return ones that are in bounds
  scanCoords = scanCoords(:,find(xCheck & yCheck & sCheck));
end



