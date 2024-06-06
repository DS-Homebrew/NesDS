#ifndef S_VRC6_H__
#define S_VRC6_H__

#ifdef __cplusplus
extern "C" {
#endif

#include <string.h>
#include "nestypes.h"
#include "audiosys.h"
#include "handler.h"
#include "nsf6502.h"
#include "nsdout.h"

#define NES_BASECYCLES (21477270)
#define CPS_SHIFT 16

typedef struct 
{
    Uint32 cps;
    Int32 cycles;
    Uint32 spd;
    Uint8 regs[3];
    Uint8 update;
    Uint8 adr;
    Uint8 mute;
} VRC6_SQUARE;

typedef struct 
{
    Uint32 cps;
    Int32 cycles;
    Uint32 spd;
    Uint32 output;
    Uint8 regs[3];
    Uint8 update;
    Uint8 adr;
    Uint8 mute;
} VRC6_SAW;

typedef struct 
{
    VRC6_SQUARE square[2];
    VRC6_SAW saw;
    Uint32 mastervolume;
} VRC6SOUND;

extern VRC6SOUND vrc6s;

//TODO: Move DivFix to a common header file
Uint32 DivFix(Uint32 p1, Uint32 p2, Uint32 fix);

void VRC6SoundSquareReset(VRC6_SQUARE *ch);
void VRC6SoundSawReset(VRC6_SAW *ch);
void VRC6SoundReset(void);

// VRC6 Mapper 24 Install and Render
void VRC6SoundInstall_24(void);
int32_t VRC6SoundRender1_24(void);
int32_t VRC6SoundRender2_24(void);
int32_t VRC6SoundRender3_24(void);

// VRC6 Mapper 26 Install and Render
void VRC6SoundInstall_26(void);
int32_t VRC6SoundRender1_26(void);
int32_t VRC6SoundRender2_26(void);
int32_t VRC6SoundRender3_26(void);

// VRC6 Mapper 24 Write functions
void VRC6SoundWrite9000_24(Uint address, Uint value);
void VRC6SoundWriteA000_24(Uint address, Uint value);
void VRC6SoundWriteB000_24(Uint address, Uint value);

// VRC6 Mapper 26 Write functions
void VRC6SoundWrite9000_26(Uint address, Uint value);
void VRC6SoundWriteA000_26(Uint address, Uint value);
void VRC6SoundWriteB000_26(Uint address, Uint value);

#ifdef __cplusplus
}
#endif

#endif /* S_VRC6_H__ */
