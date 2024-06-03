#include <nds.h>
#include <string.h>
#include "nestypes.h"
#include "audiosys.h"
#include "handler.h"
#include "nsf6502.h"
#include "nsdout.h"
#include "logtable.h"
#include "s_apu.h"
#include "c_defs.h"
#include "s_vrc6.h"

#define NES_BASECYCLES (21477270)

/* 31 - log2(NES_BASECYCLES/(12*MIN_FREQ)) > CPS_BITS  */
/* MIN_FREQ:11025 23.6 > CPS_BITS */
/* 32-12(max spd) > CPS_BITS */
#define CPS_BITS 16

#define VOL_SHIFT 9 //0

static int apuirq = 0;

/* ------------------------- */
/*  NES INTERNAL SOUND(APU)  */
/* ------------------------- */

// Based from documentation found in https://www.nesdev.org/wiki/APU

/*/ Lenght Counter /*/
// Provides automatic duration control for the NES APU waveform channels ($4015 ~ $400F)
typedef struct 
{
	Uint32 counter;			/* length counter */
	Uint8 clock_disable;	/* length counter clock disable ($4015) */
} LENGTHCOUNTER;

// Linear Counter
typedef struct 
{
	Uint32 cpf;				/* cycles per frame (240Hz fix) */
	Uint32 fc;				/* frame counter; */
	Uint8 load;				/* length counter load register */
	Uint8 start;			/* length counter start */
	Uint8 counter;		    /* length counter */
	Uint8 tocount;		    /* length counter go to count mode */
	Uint8 mode;			    /* length counter mode load(0) count(1) */
	Uint8 clock_disable;	/* length counter clock disable */
} LINEARCOUNTER;

// Envelope Decay
typedef struct 
{
	Uint8 disable;			/* envelope decay disable */
	Uint8 counter;			/* envelope decay counter */
	Uint8 rate;				/* envelope decay rate */
	Uint8 timer;			/* envelope decay timer */
	Uint8 looping_enable;	/* envelope decay looping enable */
	Uint8 volume;			/* volume */
} ENVELOPEDECAY;

// Sweep
typedef struct 
{
	Uint8 ch;				/* sweep channel */
	Uint8 active;			/* sweep active */
	Uint8 rate;				/* sweep rate */
	Uint8 timer;			/* sweep timer */
	Uint8 direction;		/* sweep direction */
	Uint8 shifter;			/* sweep shifter */
} SWEEP;

typedef struct 
{
	LENGTHCOUNTER lc;
	ENVELOPEDECAY ed;
	SWEEP sw;
	Uint32 mastervolume;
	Uint32 cps;				/* cycles per sample */
	Uint32 *cpf;			/* cycles per frame (240/192Hz) ($4017.bit7) */
	Uint32 fc;				/* frame counter; */
	Uint32 wl;				/* wave length */
	Uint32 pt;				/* programmable timer */
	Uint8 st;				/* wave step */
	Uint8 fp;				/* frame position */
	Uint8 duty;				/* duty rate */
	Uint8 key;
	Uint8 mute;
} NESAPU_SQUARE;

typedef struct 
{
	LENGTHCOUNTER lc;		/* lenght counter */
	LINEARCOUNTER li;		/* linear counter */
	Uint32 mastervolume;	/* master volume (0x0 ~ +0x3FF) */
	Uint32 cps;				/* cycles per sample */
	Uint32 *cpf;			/* cycles per frame (240/192Hz) ($4017.bit7) */
	Uint32 fc;				/* frame counter; */
	Uint32 wl;				/* wave length */
	Uint32 pt;				/* programmable timer */
	Uint8 st;				/* wave step */
	Uint8 fp;				/* frame position; */
	Uint8 key;
	Uint8 mute;
} NESAPU_TRIANGLE;

typedef struct 
{
	LENGTHCOUNTER lc;
	LINEARCOUNTER li;
	ENVELOPEDECAY ed;
	Uint32 mastervolume;
	Uint32 cps;				/* cycles per sample */
	Uint32 *cpf;			/* cycles per frame (240/192Hz) ($4017.bit7) */
	Uint32 fc;				/* frame counter; */
	Uint32 wl;				/* wave length */
	Uint32 pt;				/* programmable timer */
	Uint32 rng;
	Uint8 rngshort;
	Uint8 fp;				/* frame position; */
	Uint8 key;
	Uint8 mute;
} NESAPU_NOISE;

typedef struct 
{
	Uint32 cps;				/* cycles per sample */
	Uint32 wl;				/* wave length */
	Uint32 pt;				/* programmable timer */
	Uint32 length;			/* bit length */
	Uint32 mastervolume;
	Uint32 adr;				/* current address */
	Int32 dacout;
	Int32 dacout0;
	Uint8 start_length;
	Uint8 start_adr;
	Uint8 loop_enable;
	Uint8 irq_enable;
	Uint8 irq_report;
	Uint8 input;			/* 8bit input buffer */
	Uint8 first;
	Uint8 dacbase;
	Uint8 key;
	Uint8 mute;
} NESAPU_DPCM;

typedef struct 
{
	NESAPU_SQUARE square[2];
	NESAPU_TRIANGLE triangle;
	NESAPU_NOISE noise;
	NESAPU_DPCM dpcm;
	Uint32 cpf[3];			/* cycles per frame (240/192Hz) ($4017.bit7) */
	Uint8 regs[0x20];
} APUSOUND;

Int32 NSF_apu_volume = 0;
Int32 NSF_dpcm_volume = 0;

static APUSOUND apu;

// Square Duty LUT
static const Uint8 square_duty_table[4] = 
{ 
	0x02, 0x04, 0x08, 0x0C
};

static const Uint8 inverted_square_duty_table[4] = 
{ 
	0x0C, 0x08, 0x04, 0x02
};

// APU_Length_Counter LUT ($400F)
static const Uint8 vbl_length_table[32] = 
{
	0x0A, 0xFE, 0x14, 0x02, 0x28, 0x04, 0x50, 0x06,
	0xA0, 0x08, 0x3C, 0x0A, 0x0E, 0x0C, 0x1A, 0x0E,
	0x0C, 0x10, 0x18, 0x12, 0x30, 0x14, 0x60, 0x16,
	0xC0, 0x18, 0x48, 0x1A, 0x10, 0x1C, 0x20, 0x1E
};

// APU Noise Time Period LUT NTSC ($400E)
static const Uint32 noise_time_period_table_ntsc[16] =
{
	0x004, 0x008, 0x010, 0x020, 0x040, 0x060, 0x080, 0x0A0,
	0x0CA, 0x0FE, 0x17C, 0x1FC, 0x2FA, 0x3F8, 0x7F2, 0xFE4
};

//TODO: APU Noise Time Period LUT PAL ($400E)
static const Uint32 noise_time_period_table_pal[16] =
{
    0x004, 0x008, 0x00E, 0x01E, 0x03C, 0x058, 0x076, 0x094,
    0x0BC, 0x0EC, 0x162, 0x1D8, 0x2C4, 0x3B0, 0x762, 0xEC2
};

static const Uint32 spd_limit_table[8] =
{
	0x3FF, 0x555, 0x666, 0x71C, 0x787, 0x7C1, 0x7E0, 0x7F0
};

// APU DMC LUT NTSC ($4010)
static const Uint32 dpcm_freq_table_ntsc[16] =
{
	0x1AC, 0x17C, 0x154, 0x140, 0x11E, 0x0FE, 0x0E2, 0x0D6,
	0x0BE, 0x0A0, 0x08E, 0x080, 0x06A, 0x054, 0x048, 0x036
};

// TODO: APU DMC LUT PAL
static const Uint32 dpcm_freq_table_pal[16] =
{
	0x18E, 0x162, 0x13C, 0x12A, 0x114, 0x0EC, 0x0D2, 0x0C6,
	0x0B0, 0x094, 0x084, 0x076, 0x062, 0x04E, 0x042, 0x032
};

__inline static void LengthCounterStep(LENGTHCOUNTER *lc)
{
	if (lc->counter && !lc->clock_disable) lc->counter--;
}
__inline static void LinearCounterStep(LINEARCOUNTER *li, Uint32 cps)
{
	li->fc += cps;
	while (li->fc >= li->cpf)
	{
		li->fc -= li->cpf;
		if (li->tocount)
		{
#if 1
			li->tocount = 0;
#endif
			li->mode = 1;
		}
		if (li->mode && !li->clock_disable && li->counter && --li->counter == 0)
		{
			/* li->mode = 0; */
		}
	}
}

__inline static void EnvelopeDecayStep(ENVELOPEDECAY *ed)
{
	if (!ed->disable && ++ed->timer > ed->rate)
	{
		ed->timer = 0;
		if (ed->counter || ed->looping_enable)
			ed->counter = (ed->counter - 1) & 0xF;
	}
}

__inline void SweepStep(SWEEP *sw, Uint32 *wl)
{
	if (sw->active && sw->shifter && ++sw->timer > sw->rate)
	{
		sw->timer = 0;
		if (sw->direction)
		{
			*wl -= (*wl >> sw->shifter);
			if (*wl && !sw->ch) (*wl)--;
		}
		else
		{
			*wl += (*wl >> sw->shifter);
		}
	}
}

static Int32 NESAPUSoundSquareRender(NESAPU_SQUARE *ch)
{
	Int32 output;
	if (!ch->key || !ch->lc.counter)
	{
		return 0;
	}
	else
	{
		ch->fc += ch->cps;
		while (ch->fc >= *(ch->cpf))
		{
			ch->fc -= *(ch->cpf);
			if (!(ch->fp & 3)) LengthCounterStep(&ch->lc);	/* 60Hz */
			if (!(ch->fp & 1)) SweepStep(&ch->sw, &ch->wl);	/* 120Hz */
			EnvelopeDecayStep(&ch->ed);	/* 240Hz */
			ch->fp++;
		}
		if (!ch->sw.direction && ch->wl > spd_limit_table[ch->sw.shifter])
		{
#if 1
			return 0;
#endif
		}
		else if (ch->wl <= 4 || 0x7ff <= ch->wl)
		{
#if 1
			return 0;
#endif
		}
		else
		{
			ch->pt += ch->cps;
			while (ch->pt >= ((ch->wl + 0) << CPS_BITS))
			{
				ch->pt -= ((ch->wl + 0) << CPS_BITS);
				ch->st = (ch->st + 1) & 0xf;
			}
		}
	}

	if (ch->mute) return 0;
	output = ch->ed.disable ? ch->ed.volume : ch->ed.counter;
	//output = LinearToLog(output) + ch->mastervolume + (ch->st >= ch->duty);
	//return LogToLinear(output, LOG_LIN_BITS - LIN_BITS - VOL_SHIFT);
	if(ch->st >= ch->duty)
		return -output;
	else
		return output;
}

Int32 NESAPUSoundSquareRender1()
{
	return NESAPUSoundSquareRender(&apu.square[0]);
}

Int32 NESAPUSoundSquareRender2()
{
	return NESAPUSoundSquareRender(&apu.square[1]);
}

static Int32 NESAPUSoundTriangleRender(NESAPU_TRIANGLE *ch)
{
	Int32 output;
	if (!ch->key || !ch->lc.counter || (!ch->li.counter))
	{
#if 0
		return 0;
#endif
	}
	else
	{
		LinearCounterStep(&ch->li, ch->cps);
		ch->fc += ch->cps;
		while (ch->fc >= *(ch->cpf))
		{
			ch->fc -= *(ch->cpf);
			if (!(ch->fp & 3)) LengthCounterStep(&ch->lc);	/* 60Hz */
			ch->fp++;
		}
#if 0
		/*
			(Japanese:sjis memo)
			��΂Ȃǂ̒ቹ�O�p�g���J�b�g�������ꍇ�L��������B
			�V�t�@�~�ł͔������m�F�B
		*/
		if (ch->wl >= 0x7ff)
		{
			return 0;
		}
		else
#endif
		if (ch->wl <= 4)
		{
#if 0
			return 0;
#endif
		}
		else
		{
			ch->pt += ch->cps;
			while (ch->pt >= ((ch->wl + 0) << CPS_BITS))
			{
				ch->pt -= ((ch->wl + 0) << CPS_BITS);
				ch->st++;
			}
		}
	}
	if (ch->mute) return 0;
	output = ch->st & 0x7;
	if (ch->st & 0x8) output = output ^ 0x7;
	//output = LinearToLog(output) + ch->mastervolume + ((ch->st >> 4) & 1);
	//return LogToLinear(output, LOG_LIN_BITS - LIN_BITS - VOL_SHIFT + 2);
	if((ch->st >> 4) & 1)
		return -output;
	else
		return output;
}

Int32 NESAPUSoundTriangleRender1()
{
	return NESAPUSoundTriangleRender(&apu.triangle);
}

static Int32 NESAPUSoundNoiseRender(NESAPU_NOISE *ch)
{
	Int32 output;
	if (!ch->key || !ch->lc.counter) return 0;
	ch->fc += ch->cps;
	while (ch->fc >= *(ch->cpf))
	{
		ch->fc -= *(ch->cpf);
		if (!(ch->fp & 3)) LengthCounterStep(&ch->lc);	/* 60Hz */
		EnvelopeDecayStep(&ch->ed);						/* 240Hz */
		ch->fp++;
	}
	if (!ch->wl) return 0;
	ch->pt += ch->cps;
	while (ch->pt >= (ch->wl << (CPS_BITS + 1)))
	{
		ch->pt -= ch->wl << (CPS_BITS + 1);
		ch->rng >>= 1;
		ch->rng |= ((ch->rng ^ (ch->rng >> (ch->rngshort ? 6 : 1))) & 1) << 15;
	}
	if (ch->mute) return 0;
	output = ch->ed.disable ? ch->ed.volume : ch->ed.counter;
	// output = LinearToLog(output) + ch->mastervolume + (ch->rng & 1);
	// return LogToLinear(output, LOG_LIN_BITS - LIN_BITS - VOL_SHIFT);
	output &= 0xF;
	if(ch->rng & 1)
		return -output;
	else
		return output;
}

Int32 NESAPUSoundNoiseRender1()
{
	return NESAPUSoundNoiseRender(&apu.noise);
}

__inline static void NESAPUSoundDpcmRead(NESAPU_DPCM *ch)
{
	char ** memtbl = IPC_MEMTBL;
	int addr = ch->adr;
	//ch->input = NES6502ReadDma(ch->adr);
	ch->input = memtbl[(addr>>13) - 4][addr&0x1FFF];
	//if (NSD_out_mode) NSDWrite(NSD_APU, ch->adr, ch->input);
	ch->adr++;
}

static void NESAPUSoundDpcmStart(NESAPU_DPCM *ch)
{
	ch->adr = 0xC000 + ((Uint)ch->start_adr << 6);
	ch->length = (((Uint)ch->start_length << 4) + 1) << 3;
	ch->irq_report = 0;
	NESAPUSoundDpcmRead(ch);
}

static Int32 __fastcall NESAPUSoundDpcmRender(void)
{
#define ch (&apu.dpcm)
	if (ch->first)
	{
		ch->first = 0;
		ch->dacbase = ch->dacout;
	}
	if (ch->key && ch->length)
	{
		ch->pt += ch->cps;
		while (ch->pt >= ((ch->wl + 0) << CPS_BITS))
		{
			ch->pt -= ((ch->wl + 0) << CPS_BITS);
			if (ch->length == 0) continue;
			if (ch->input & 1)
				ch->dacout += (ch->dacout < +0x3f);
			else
				ch->dacout -= (ch->dacout > 0);
			ch->input >>= 1;

			if (--ch->length == 0)
			{
				if (ch->loop_enable)
				{
					NESAPUSoundDpcmStart(ch);	/*loop */
				}
				else
				{
					if (ch->irq_enable)
					{
						//NES6502Irq();	/* irq gen */
						apuirq = 0xFF;
						ch->irq_report = 0x80;
					}
					ch->length = 0;
				}
			}
			else if ((ch->length & 7) == 0)
			{
				NESAPUSoundDpcmRead(ch);
			}
		}
		if (ch->mute) return 0;
		return ((ch->dacout << 1) + ch->dacout0 - 0x40);
	}
	return 0;
/*
#if 1
	return LogToLinear(LinearToLog((ch->dacout << 1) + ch->dacout0 - ch->dacbase) + ch->mastervolume, LOG_LIN_BITS - LIN_BITS - VOL_SHIFT);
#else
	return LogToLinear(LinearToLog((ch->dacout << 1) + ch->dacout0) + ch->mastervolume, LOG_LIN_BITS - LIN_BITS - VOL_SHIFT + 1)
		 - LogToLinear(LinearToLog( ch->dacbase                   ) + ch->mastervolume, LOG_LIN_BITS - LIN_BITS - VOL_SHIFT + 1);
#endif*/
#undef ch
}

Int32 NESAPUSoundDpcmRender1()
{
	return NESAPUSoundDpcmRender();
}

static Int32 __fastcall APUSoundRender(void)
{
	Int32 accum = 0;
	//accum += NESAPUSoundSquareRender(&apu.square[0]);
	//accum += NESAPUSoundSquareRender(&apu.square[1]);
	//accum += NESAPUSoundTriangleRender(&apu.triangle);
	//accum += NESAPUSoundNoiseRender(&apu.noise);
	//accum += NESAPUSoundDpcmRender();
	return accum;
}

static NES_AUDIO_HANDLER s_apu_audio_handler[] = 
{
	{ 1, APUSoundRender, 0, 0}, 
	{ 0, 0, 0}
};

static void __fastcall APUSoundVolume(Uint volume)
{
	volume  = 127;
	//volume += (NSF_apu_volume << (LOG_BITS - 8)) << 1;
	
	/* SND1 */
	apu.square[0].mastervolume = volume;
	apu.square[1].mastervolume = volume;

	/* SND2 */
	apu.triangle.mastervolume = volume;
	apu.noise.mastervolume = volume;

	volume += 127;
	apu.dpcm.mastervolume = volume;
}

static NES_VOLUME_HANDLER s_apu_volume_handler[] = {
	{ APUSoundVolume, 0},
	{ 0, 0}
};

void APUSoundWrite(Uint address, Uint value)
{
	// NES APU REGISTERS ($4000 ~ $4017)
	if (0x4000 <= address && address <= 0x4017)
	{
		//if (NSD_out_mode && address <= 0x4015) NSDWrite(NSD_APU, address, value);
		apu.regs[address - 0x4000] = value;
		switch (address)
		{
			//***Square Wave - Pulse ($4000–$4007)***//

			// Duty Cycle ($4000 / $4004)
			case 0x4000:	case 0x4004:
				{
					int ch = address >= 0x4004;
					// TODO: Invert Duty Cycles option
					if (value & 0x10)
						apu.square[ch].ed.volume = value & 0x0f;
					else
					{
						apu.square[ch].ed.rate   = value & 0x0f;
					}
					apu.square[ch].ed.disable = value & 0x10;
					apu.square[ch].lc.clock_disable = value & 0x20;
					apu.square[ch].ed.looping_enable = value & 0x20;
					// TODO: Invert Duty Cycles option
					if (getApuCurrentStatus() == Reverse)
					    apu.square[ch].duty = inverted_square_duty_table[value >> 6];
					else 
					{
						apu.square[ch].duty = square_duty_table[value >> 6];
					}
				}
				break;

			// Sweep unit ($4001 / $4005)
			case 0x4001:	case 0x4005:
				{
					int ch = address >= 0x4004;
					apu.square[ch].sw.shifter = value & 7;
					apu.square[ch].sw.direction = value & 8;
					apu.square[ch].sw.rate = (value >> 4) & 7;
					apu.square[ch].sw.active = value & 0x80;
					apu.square[ch].sw.timer = 0;
				}
				break;

			// Timer low ($4002 / $4006)
			case 0x4002:	case 0x4006:
				{
					int ch = address >= 0x4004;
					apu.square[ch].wl &= 0x700;
					apu.square[ch].wl += value;
				}
				break;

			// 	Length counter load ($4003 / $4007)
			case 0x4003:	case 0x4007:
				{
					int ch = address >= 0x4004;
					// apu.square[ch].pt = 0;
#if 1
					apu.square[ch].st = 0;
#endif
					apu.square[ch].wl &= 0x0ff;
					apu.square[ch].wl += (value & 7) << 8;
					apu.square[ch].ed.counter = 0xf;
					// Divided by 2 to match DS freq 
					apu.square[ch].lc.counter = (vbl_length_table[value >> 3]) >> 1;
				}
				break;

			//***Triangle ($4008–$400B)***//

			// Length counter halt, linear counter control/load ($4008)
			case 0x4008:
				apu.triangle.li.load = value & 0x7f;
				if (apu.triangle.li.start)
				{
					if (!(value & 0x80))
						apu.triangle.li.tocount = 1;
					/*
						(Japanese:sjis memo)
						NESSOUND.TXT�ɏ���������������
						Just Breed/Super Mario Bros. 3�ňُ�
						no chane->load
					*/
					apu.triangle.li.mode = 0;
					/* if (!apu.triangle.li.mode) */
						apu.triangle.li.counter = apu.triangle.li.load;
				}
				else
				{
					if (!apu.triangle.li.mode)
						apu.triangle.li.counter = apu.triangle.li.load;
					apu.triangle.li.mode = 1;
				}
				apu.triangle.li.clock_disable = value & 0x80;
				apu.triangle.lc.clock_disable = value & 0x80;
				apu.triangle.li.start = value & 0x80;
				break;

			// Timer Low ($400A)	
			case 0x400a:
				apu.triangle.wl &= 0x700;
				apu.triangle.wl += value;
				break;

			//	Length counter load, timer high, set linear counter reload flag ($400B)
			case 0x400b:
				apu.triangle.wl &= 0x0ff;
				apu.triangle.wl += (value & 7) << 8;
				// Divided by 2 to match DS freq 
				apu.triangle.lc.counter = (vbl_length_table[value >> 3]) >> 1;
				apu.triangle.li.mode = 0;
				/* if (!apu.triangle.li.mode) */
					apu.triangle.li.counter = apu.triangle.li.load;
				if (!apu.triangle.li.start)
					apu.triangle.li.tocount = 1;
				break;

			//***Noise ($400C–$400F)***//

			// Envelope loop/lenght counter halt/envelope ($400C)
			case 0x400c:
				if (value & 0x10)
					apu.noise.ed.volume = value & 0x0f;
				else
				{
					apu.noise.ed.rate = value & 0x0f;
				}
				apu.noise.ed.disable = value & 0x10;
				apu.noise.lc.clock_disable = value & 0x20;
				apu.noise.ed.looping_enable = value & 0x20;
				break;

			// Loop noise/period ($400E)
			case 0x400e:
			    // Divided by 2 to match DS freq 

				if(getApuCurrentRegion() == PAL)
				{
					apu.noise.wl = (noise_time_period_table_pal[value & 0x0F]) >> 1;
				} else {
					apu.noise.wl = (noise_time_period_table_ntsc[value & 0x0F]) >> 1;
				}
				apu.noise.rngshort = value & 0x80;
				break;

			// Length counter load ($400F)
			case 0x400f:
				// apu.noise.rng = 0x8000;
				apu.noise.ed.counter = 0xF;
				// Divided by 2 to match DS freq 
				apu.noise.lc.counter = (vbl_length_table[value >> 3]) >> 1;
				break;
            
			//***DMC ($4010–$4013)***//

			// IRQ enable, loop, freq ($4010)
			case 0x4010:
				if(getApuCurrentRegion() == PAL)
				{
					apu.dpcm.wl = dpcm_freq_table_pal[value & 0x0F];
				}
				else
				{
					apu.dpcm.wl = dpcm_freq_table_ntsc[value & 0x0F];
				}
				apu.dpcm.loop_enable = value & 0x40;
				apu.dpcm.irq_enable = value & 0x80;
				if (!apu.dpcm.irq_enable) apu.dpcm.irq_report = 0;
				break;

			// Load Counter ($4011)	
			case 0x4011:
#if 0
				if (apu.dpcm.first && (value & 0x7f))
				{
					apu.dpcm.first = 0;
					apu.dpcm.dacbase = value & 0x7f;
				}
#endif
				apu.dpcm.dacout = (value >> 1) & 0x3f;
				apu.dpcm.dacbase = value & 0x7f;
				apu.dpcm.dacout0 = value & 1;
				break;

			// Sample address ($4012)
			case 0x4012:
				apu.dpcm.start_adr = value;
				break;

			// Sample length ($4013)
			case 0x4013:
				apu.dpcm.start_length = value;
				break;

			//***Status ($4015)***//

			// Write/Read ($4015)
			case 0x4015:
				if (value & 1)
					apu.square[0].key = 1;
				else
				{
					apu.square[0].key = 0;
					apu.square[0].lc.counter = 0;
				}
				if (value & 2)
					apu.square[1].key = 1;
				else
				{
					apu.square[1].key = 0;
					apu.square[1].lc.counter = 0;
				}
				if (value & 4)
					apu.triangle.key = 1;
				else
				{
					apu.triangle.key = 0;
					apu.triangle.lc.counter = 0;
					apu.triangle.li.counter = 0;
					apu.triangle.li.mode = 0;
				}
				if (value & 8)
					apu.noise.key = 1;
				else
				{
					apu.noise.key = 0;
					apu.noise.lc.counter = 0;
				}
				if (value & 16)
				{
					if (!apu.dpcm.key)
					{
						apu.dpcm.key = 1;
						NESAPUSoundDpcmStart(&apu.dpcm);
					}
				}
				else
				{
					apu.dpcm.key = 0;
				}
				break;

			// Frame Counter ($4017)	
			case 0x4017:
				if (value & 0x80)
					apu.cpf[0] = apu.cpf[2];
				else
					apu.cpf[0] = apu.cpf[1];
				break;
		}
	}

	// FDS (FAMICOM DISK SYSTEM ADDITIONAL CHANNEL) TODO: REFACTOR WITH CASES
	else if(0x4040 <= address && address < 0x4090) 
	{
		FDSSoundWriteHandler(address, value);
	}

	// VRC6 (KONAMI SOUND CHIP) TODO: REFACTOR WITH CASES
	else if(0x8000 <= address && address < 0xffff) 
	{
		if(0x9000 <= address && address <= 0x9002) 
		{
			VRC6SoundWrite9000(address, value);
		}
		else if(0xA000 <= address && address <= 0xA002) 
		{
			VRC6SoundWriteA000(address, value);
		}
		else if(0xB000 <= address && address <= 0xB002) 
		{
			VRC6SoundWriteB000(address, value);
		}
	}
}

/*
static NES_WRITE_HANDLER s_apu_write_handler[] =
{
	{ 0x4000, 0x4017, APUSoundWrite, 0},
	{ 0, 0, 0, 0}
};


static Uint __fastcall APUSoundRead(Uint address)
{
	if (0x4015 == address)
	{
		int key = 0;
		if (apu.square[0].key && apu.square[0].lc.counter) key |= 1;
		if (apu.square[1].key && apu.square[1].lc.counter) key |= 2;
		if (apu.triangle.key && apu.triangle.lc.counter && apu.triangle.li.counter) key |= 4;
		if (apu.noise.key && apu.noise.lc.counter) key |= 8;
		if (apu.dpcm.length) key |= 16;
		return key | 0x40 | apu.dpcm.irq_report;
	}
	if (0x4000 <= address && address <= 0x4017)
		return apu.regs[address - 0x4000];
	return 0xFF;
}


static NES_READ_HANDLER s_apu_read_handler[] =
{
	{ 0x4000, 0x4017, APUSoundRead, 0},
	{ 0,      0,      0, 0}
};
*/

// Needs review
void __fastcall APU4015Reg()
{
	static int oldkey = 0;
	int key = 0;
	if (apu.square[0].key && apu.square[0].lc.counter)
		key |= 1;
	if (apu.square[1].key && apu.square[1].lc.counter) 
		key |= 2;
	if (apu.triangle.key && apu.triangle.lc.counter && apu.triangle.li.counter) 
		key |= 4;
	if (apu.noise.key && apu.noise.lc.counter) 
		key |= 8;
	if (apu.dpcm.length) 
		key |= 16;
	
	key = key | 0x40 | apu.dpcm.irq_report;
	if (oldkey != key || apuirq) 
	{
		IPC_REG4015 = key;
		IPC_APUIRQ = apuirq;
		oldkey = key;
		apuirq = 0;
	}
}

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

static void NESAPUSoundSquareReset(NESAPU_SQUARE *ch)
{
	XMEMSET(ch, 0, sizeof(NESAPU_SQUARE));
		if(getApuCurrentRegion() == PAL)
	{
		ch->cps = DivFix((NES_BASECYCLES << 1), 13 * (NESAudioFrequencyGet() << 1), CPS_BITS);
	}
	else
	{
		ch->cps = DivFix(NES_BASECYCLES, 12 * NESAudioFrequencyGet(), CPS_BITS);
	}
}
static void NESAPUSoundTriangleReset(NESAPU_TRIANGLE *ch)
{
	XMEMSET(ch, 0, sizeof(NESAPU_TRIANGLE));
	if(getApuCurrentRegion() == PAL)
	{
		ch->cps = DivFix((NES_BASECYCLES << 1), 13 * (NESAudioFrequencyGet() << 1), CPS_BITS);
	}
	else
	{
		ch->cps = DivFix(NES_BASECYCLES, 12 * NESAudioFrequencyGet(), CPS_BITS);
	}
}
static void NESAPUSoundNoiseReset(NESAPU_NOISE *ch)
{
	XMEMSET(ch, 0, sizeof(NESAPU_NOISE));
	ch->cps = DivFix(NES_BASECYCLES, 12 * NESAudioFrequencyGet(), CPS_BITS);
	ch->rng = 0x80;
}


static void NESAPUSoundDpcmReset(NESAPU_DPCM *ch)
{
	XMEMSET(ch, 0, sizeof(NESAPU_DPCM));
	if(getApuCurrentRegion() == PAL)
	{
		ch->cps = DivFix((NES_BASECYCLES << 1), 13 * (NESAudioFrequencyGet() << 1), CPS_BITS);
	}
	else
	{
		ch->cps = DivFix(NES_BASECYCLES, 12 * NESAudioFrequencyGet(), CPS_BITS);
	}
}

static void __fastcall APUSoundReset(void)
{
	Uint i;
	NESAPUSoundSquareReset(&apu.square[0]);
	NESAPUSoundSquareReset(&apu.square[1]);
	NESAPUSoundTriangleReset(&apu.triangle);
	NESAPUSoundNoiseReset(&apu.noise);
	NESAPUSoundDpcmReset(&apu.dpcm);
	apu.cpf[1] = DivFix(NES_BASECYCLES, 12 * 240, CPS_BITS);
	apu.cpf[2] = DivFix(NES_BASECYCLES, 12 * 240 * 4 / 5, CPS_BITS);
	apu.cpf[0] = apu.cpf[1];
	apu.square[1].sw.ch = 1;
	apu.square[0].cpf = &apu.cpf[0];
	apu.square[1].cpf = &apu.cpf[0];
	apu.triangle.cpf = &apu.cpf[0];
	apu.noise.cpf = &apu.cpf[0];
	apu.triangle.li.cpf = apu.cpf[1];

	for (i = 0; i <= 0x17; i++)
	{
		APUSoundWrite(0x4000 + i, (i == 0x10) ? 0x10 : 0x00);
	}
	APUSoundWrite(0x4015, 0x0f);
#if 1
	apu.dpcm.first = 1;
#endif
}

static NES_RESET_HANDLER s_apu_reset_handler[] = {
	{ NES_RESET_SYS_NOMAL, APUSoundReset, 0}, 
	{ 0,                   0, 0}
};

void APUSoundInstall(void)
{
	NESAudioHandlerInstall(s_apu_audio_handler);
	NESVolumeHandlerInstall(s_apu_volume_handler);
	//NESReadHandlerInstall(s_apu_read_handler);
	//NESWriteHandlerInstall(s_apu_write_handler);
	NESResetHandlerInstall(s_apu_reset_handler);
}
