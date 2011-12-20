#ifdef __cplusplus
extern "C" {
#endif

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

#ifdef __cplusplus
}
#endif

#include <stdint.h>
#include <math.h>

typedef unsigned char uint8;

static uint8 colorBall = 0x01;
static uint8 colorField = 0x08;
static uint8 colorWhite = 0x10;

int lua_field_occupancy(lua_State *L) {
  // Check arguments
  uint8_t *im_ptr = (uint8_t *) lua_touserdata(L, 1);
  if ((im_ptr == NULL) || !lua_islightuserdata(L, 1)) {
    return luaL_error(L, "Input image not light user data");
  }  
  int ni = luaL_checkint(L, 2);
  int nj = luaL_checkint(L, 3);
  const int nRegions = ni;

  int count[nRegions];
  int countpos[nRegions];
  for (int i = 0; i < nRegions; i++) {
    count[i] = 0;
    countpos[i] = 0;
  }

  // Scan vertical lines:
  float aveval = 0; // average position based on value 
  float aveidx = 0; // average position based on index
  for (int i = 0; i < ni; i++) {
    int iRegion = nRegions*i/ni;
    uint8 *im_row = im_ptr + i;
    for (int j = 0; j < nj; j++) {
      uint8 label = *im_row;
      if ((label & colorField) || (label & colorBall) || (label & colorWhite)) {
        count[iRegion]++;
        countpos[iRegion] += (j + 1);
      }
      im_row += ni;
    }
    if (count[i] != 0){
      aveval = nj - count[i]/2;
      aveidx = countpos[i]/count[i];
      if (fabs(aveval-aveidx) > 0.1*nj){
        // printf("recalibrate\n");
        count[i] = 0; 
        uint8 *im_row = im_ptr + i;
        for (int j = aveidx; j < nj; j++) {
          uint8 label = *im_row;
          if ((label & colorField) || (label & colorBall) || (label & colorWhite))
            count[i]++;
          im_row += ni;
        }      
      }
    }
  }
  
  lua_createtable(L,nRegions,0);
  for (int i = 0; i < nRegions; i++){
    lua_pushinteger(L, count[i]);
    lua_rawseti(L, -2, i+1);
  }
  return 1;
}
