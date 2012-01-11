module(..., package.seeall);

require('Config');	-- For Ball and Goal Size
require('ImageProc');
require('HeadTransform');	-- For Projection
require('Vision');
require('Debug');
require('shm');
require('vcm');
require('Body');
require('vector');


headZ = Config.head.camOffsetZ;

function detect(color)
  local boundary = {};
  boundary.detect = 1;
  boundary.top = {};
  boundary.bottom = {};

--  local topV = vcm.get_freespace_vboundB(); 
  -- Separate Frame into 8 columns : 80 x 60
  local nCol = Vision.labelB.m;
  -- Search label A column by column for freespace
  for nC = 1 , nCol do
    -- Search box width
    local Xoff = Vision.labelA.m/nCol;
    local topB = {nC,1};
	local bottomB = {nC,Vision.labelB.n}

    --Project to 2D coordinate
    local topV = HeadTransform.rayIntersectB(topB);
    local bottomV = HeadTransform.rayIntersectB(bottomB); 

    boundary.top[nC],boundary.top[nC+nCol] = topV[1],topV[2];
    boundary.bottom[nC],boundary.bottom[nC+nCol] = bottomV[1],bottomV[2];
  end -- end for search for columns
  return boundary;
end
