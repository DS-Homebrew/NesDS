#include <string.h>
#include "nestypes.h"
#include "audiosys.h"
#include "handler.h"
#include "nsf6502.h"
#include "nsdout.h"
#include "logtable.h"
#include "s_fds.h"

#define FDS_DYNAMIC_BIAS 1


#define FM_DEPTH 0 /* 0,1,2 */
#define NES_BASECYCLES (21477270)
#define PGCPS_BITS (32-16-6)
#define EGCPS_BITS (12)
#define VOL_BITS 12

typedef struct {
	Uint8 spd;
	Uint8 cnt;
	Uint8 mode;
	Uint8 volume;
} FDS_EG;
typedef struct {
	Uint32 spdbase;
	Uint32 spd;
	Uint32 freq;
} FDS_PG;
typedef struct {
	Uint32 phase;
	Int8 wave[0x40];
	Uint8 wavptr;
	Int8 output;
	Uint8 disable;
	Uint8 disable2;
} FDS_WG;
typedef struct {
	FDS_EG eg;
	FDS_PG pg;
	FDS_WG wg;
	Uint8 bias;
	Uint8 wavebase;
	Uint8 d[2];
} FDS_OP;

typedef struct FDSSOUND_tag {
	FDS_OP op[2];
	Uint32 phasecps;
	Uint32 envcnt;
	Uint32 envspd;
	Uint32 envcps;
	Uint8 envdisable;
	Uint8 d[3];
	Uint32 lvl;
	Int32 mastervolumel[4];
	Uint32 mastervolume;
	Uint32 srate;
	Uint8 reg[0x10];
} FDSSOUND;

static FDSSOUND fdssound;

static void FDSSoundWGStep(FDS_WG *pwg)
{
#if 0
	if (pwg->disable | pwg->disable2)
		pwg->output = 0;
	else
		pwg->output = pwg->wave[(pwg->phase >> (PGCPS_BITS+16)) & 0x3f];
#else
	if (pwg->disable || pwg->disable2) return;
	pwg->output = pwg->wave[(pwg->phase >> (PGCPS_BITS+16)) & 0x3f];
#endif
}

static void FDSSoundEGStep(FDS_EG *peg)
{
	if (peg->mode & 0x80) return;
	if (++peg->cnt <= peg->spd) return;
	peg->cnt = 0;
	if (peg->mode & 0x40)
		peg->volume += (peg->volume < 0x1f);
	else
		peg->volume -= (peg->volume > 0);
}

static Int32 __fastcall FDSSoundRender(void)
{
	Int32 output;
	
	/* Wave Generator */
	FDSSoundWGStep(&fdssound.op[1].wg);
	FDSSoundWGStep(&fdssound.op[0].wg);

	/* Frequency Modulator */
	fdssound.op[1].pg.spd = fdssound.op[1].pg.spdbase;
	if (fdssound.op[1].wg.disable)
		fdssound.op[0].pg.spd = fdssound.op[0].pg.spdbase;
	else
	{
		Uint32 v1;
#if FDS_DYNAMIC_BIAS
		v1 = 0x10000 + ((Int32)fdssound.op[1].eg.volume) * (((Int32)((((Uint8)fdssound.op[1].wg.output) + fdssound.op[1].bias) & 255)) - 64);
#else
		v1 = 0x10000 + ((Int32)fdssound.op[1].eg.volume) * (((Int32)((((Uint8)fdssound.op[1].wg.output)                      ) & 255)) - 64);
#endif
		v1 = ((1 << 10) + v1) & 0xfff;
		v1 = (fdssound.op[0].pg.freq * v1) >> 10;
		fdssound.op[0].pg.spd = v1 * fdssound.phasecps;
	}

	/* Accumulator */
	output = fdssound.op[0].eg.volume;
	if (output > 0x20) output = 0x20;
	output = (fdssound.op[0].wg.output * output);// * fdssound.mastervolumel[fdssound.lvl]) >> (VOL_BITS - 4);

	/* Envelope Generator */
	if (!fdssound.envdisable && fdssound.envspd)
	{
		fdssound.envcnt += fdssound.envcps;
		while (fdssound.envcnt >= fdssound.envspd)
		{
			fdssound.envcnt -= fdssound.envspd;
			FDSSoundEGStep(&fdssound.op[1].eg);
			FDSSoundEGStep(&fdssound.op[0].eg);
		}
	}

	/* Phase Generator */
	fdssound.op[1].wg.phase += fdssound.op[1].pg.spd;
	fdssound.op[0].wg.phase += fdssound.op[0].pg.spd;
	return (fdssound.op[0].pg.freq != 0) ? output : 0;
}

Int32 FDSSoundRender3(void)
{
	return FDSSoundRender();
}


static NES_AUDIO_HANDLER s_fds_audio_handler[] =
{
	{ 1, FDSSoundRender, }, 
	{ 0, 0, }, 
};

static void __fastcall FDSSoundVolume(Uint volume)
{
	volume += 196;
	fdssound.mastervolume = (volume << (LOG_BITS - 8)) << 1;/*
	fdssound.mastervolumel[0] = LogToLinear(fdssound.mastervolume, LOG_LIN_BITS - LIN_BITS - VOL_BITS) * 2;
	fdssound.mastervolumel[1] = LogToLinear(fdssound.mastervolume, LOG_LIN_BITS - LIN_BITS - VOL_BITS) * 4 / 3;
	fdssound.mastervolumel[2] = LogToLinear(fdssound.mastervolume, LOG_LIN_BITS - LIN_BITS - VOL_BITS) * 2 / 2;
	fdssound.mastervolumel[3] = LogToLinear(fdssound.mastervolume, LOG_LIN_BITS - LIN_BITS - VOL_BITS) * 8 / 10;*/
}

static NES_VOLUME_HANDLER s_fds_volume_handler[] = {
	{ FDSSoundVolume, }, 
	{ 0, }, 
};

static const Uint8 wave_delta_table[8] = {
	0,(1 << FM_DEPTH),(2 << FM_DEPTH),(4 << FM_DEPTH),
	0,256 - (4 << FM_DEPTH),256 - (2 << FM_DEPTH),256 - (1 << FM_DEPTH),
};

static void __fastcall FDSSoundWrite(Uint address, Uint value)
{
	if (0x4040 <= address && address <= 0x407F)
	{
		fdssound.op[0].wg.wave[address - 0x4040] = ((int)(value & 0x3f)) - 0x20;
	}
	else if (0x4080 <= address && address <= 0x408F)
	{
		FDS_OP *pop = &fdssound.op[(address & 4) >> 2];
		fdssound.reg[address - 0x4080] = value;
		switch (address & 0xf)
		{
			case 0:
			case 4:
				pop->eg.mode = value & 0xc0;
				if (pop->eg.mode & 0x80)
				{
					pop->eg.volume = (value & 0x3f);
				}
				else
				{
					pop->eg.spd = value & 0x3f;
				}
				break;
			case 5:
#if 1
				fdssound.op[1].bias = value & 255;
#else
				fdssound.op[1].bias = (((value & 0x7f) ^ 0x40) - 0x40) & 255;
#endif
#if 0
				fdssound.op[1].wg.phase = 0;
#endif
				break;
			case 2:	case 6:
				pop->pg.freq &= 0x00000F00;
				pop->pg.freq |= (value & 0xFF) << 0;
				pop->pg.spdbase = pop->pg.freq * fdssound.phasecps;
				break;
			case 3:
				fdssound.envdisable = value & 0x40;
			case 7:
#if 0
				pop->wg.phase = 0;
#endif
				pop->pg.freq &= 0x000000FF;
				pop->pg.freq |= (value & 0x0F) << 8;
				pop->pg.spdbase = pop->pg.freq * fdssound.phasecps;
				pop->wg.disable = value & 0x80;
				if (pop->wg.disable)
				{
					pop->wg.phase = 0;
					pop->wg.wavptr = 0;
					pop->wavebase = 0;
				}
				break;
			case 8:
				if (fdssound.op[1].wg.disable)
				{
					Int32 idx = value & 7;
					if (idx == 4)
					{
						fdssound.op[1].wavebase = 0;
					}
#if FDS_DYNAMIC_BIAS
					fdssound.op[1].wavebase += wave_delta_table[idx];
					fdssound.op[1].wg.wave[fdssound.op[1].wg.wavptr + 0] = (fdssound.op[1].wavebase + 64) & 255;
					fdssound.op[1].wavebase += wave_delta_table[idx];
					fdssound.op[1].wg.wave[fdssound.op[1].wg.wavptr + 1] = (fdssound.op[1].wavebase + 64) & 255;
					fdssound.op[1].wg.wavptr = (fdssound.op[1].wg.wavptr + 2) & 0x3f;
#else
					fdssound.op[1].wavebase += wave_delta_table[idx];
					fdssound.op[1].wg.wave[fdssound.op[1].wg.wavptr + 0] = (fdssound.op[1].wavebase + fdssound.op[1].bias + 64) & 255;
					fdssound.op[1].wavebase += wave_delta_table[idx];
					fdssound.op[1].wg.wave[fdssound.op[1].wg.wavptr + 1] = (fdssound.op[1].wavebase + fdssound.op[1].bias + 64) & 255;
					fdssound.op[1].wg.wavptr = (fdssound.op[1].wg.wavptr + 2) & 0x3f;
#endif
				}
				break;
			case 9:
				fdssound.lvl = (value & 3);
				fdssound.op[0].wg.disable2 = value & 0x80;
				break;
			case 10:
				fdssound.envspd = value << EGCPS_BITS;
				break;
		}
	}
}
/*
static NES_WRITE_HANDLER s_fds_write_handler[] =
{
	{ 0x4040, 0x408F, FDSSoundWrite, },
	{ 0,      0,      0, },
};

static Uint __fastcall FDSSoundRead(Uint address)
{
	if (0x4040 <= address && address <= 0x407f)
	{
		return fdssound.op[0].wg.wave[address & 0x3f] + 0x20;
	}
	if (0x4090 == address)
		return fdssound.op[0].eg.volume | 0x40;
	if (0x4092 == address) //4094?
		return fdssound.op[1].eg.volume | 0x40;
	return 0;
}

static NES_READ_HANDLER s_fds_read_handler[] =
{
	{ 0x4040, 0x409F, FDSSoundRead, },
	{ 0,      0,      0, },
};*/

static Uint32 DivFix(Uint32 p1, Uint32 p2, Uint32 fix)
{
	Uint32 ret;
	ret = p1 / p2;
	p1  = p1 % p2;/* p1 = p1 - p2 * ret; */
	while (fix--)
	{
		p1 += p1;
		ret += ret;
		if (p1 >= p2)
		{
			p1 -= p2;
			ret++;
		}
	}
	return ret;
}

static void __fastcall FDSSoundReset(void)
{
	Uint32 i;
	XMEMSET(&fdssound, 0, sizeof(FDSSOUND));
	fdssound.srate = NESAudioFrequencyGet();
	fdssound.envcps = DivFix(NES_BASECYCLES, 12 * fdssound.srate, EGCPS_BITS + 5 - 9 + 1);
	fdssound.envspd = 0xe8 << EGCPS_BITS;
	fdssound.envdisable = 1;
	fdssound.phasecps = DivFix(NES_BASECYCLES, 12 * fdssound.srate, PGCPS_BITS);
	for (i = 0; i < 0x40; i++)
	{
		fdssound.op[0].wg.wave[i] = (i < 0x20) ? 0x1f : -0x20;
		fdssound.op[1].wg.wave[i] = 64;
	}
}

static NES_RESET_HANDLER s_fds_reset_handler[] =
{
	{ NES_RESET_SYS_NOMAL, FDSSoundReset, }, 
	{ 0,                   0, }, 
};

void FDSSoundInstall3(void)
{
	//LogTableInitialize();
	NESAudioHandlerInstall(s_fds_audio_handler);
	NESVolumeHandlerInstall(s_fds_volume_handler);
	//NESReadHandlerInstall(s_fds_read_handler);
	//NESWriteHandlerInstall(s_fds_write_handler);
	FDSSoundWriteHandler = FDSSoundWrite;
	NESResetHandlerInstall(s_fds_reset_handler);
}
