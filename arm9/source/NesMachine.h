#ifndef NESMACHINE_HEADER
#define NESMACHINE_HEADER

#ifdef __cplusplus
extern "C" {
#endif

#include "RP2A03.h"
#include "RP2C02.h"

typedef struct {
	RP2A03 cpu;
	RP2C02 ppu;
	u8 mapperData[96];

	u8 *romBase;
	u32 romMask;
	u32 prgSize8k;
	u32 prgSize16k;
	u32 prgSize32k;
	u32 mapperNr;
	u32 emuFlags;
	u32 prgCrc;

	u32 lightY;

	u32 renderCount;
	u32 tempData[20];

	u8 cartFlags;
	u8 subMapper;
	u8 padding[2];
} NESCore;

extern RP2A03 rp2A03;
extern NESCore globals;

#ifdef __cplusplus
}
#endif

#endif // NESMACHINE_HEADER
