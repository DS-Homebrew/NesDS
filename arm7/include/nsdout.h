#ifndef NSDOUT_H__
#define NSDOUT_H__

#include "nestypes.h"

#ifdef __cplusplus
extern "C" {
#endif

extern Uint NSD_out_mode;
enum
{
	NSD_NSF_MAPPER,
	NSD_VSYNC,
	NSD_APU,
	NSD_VRC6,
	NSD_VRC7,
	NSD_FDS,
	NSD_MMC5,
	NSD_N106,
	NSD_FME7,
	NSD_INITEND,
	NSD_MAX
};
void NSDStart(Uint syncmode);
void NSDWrite(Uint device, Uint address, Uint value);
void NSDTerm(void (*Output)(void *p, Uint l));

#ifdef __cplusplus
}
#endif

#endif /* NSDOUT_H__ */
