#include "audiosys.h"

/* ---------------------- */
/*  Audio Render Handler  */
/* ---------------------- */

#define SHIFT_BITS 8

static Uint frequency = 44100;
static Uint channel = 1;

static NES_AUDIO_HANDLER *nah = 0;
static NES_VOLUME_HANDLER *nvh = 0;

static Uint naf_type = NES_AUDIO_FILTER_LOWPASS;
static Uint32 naf_prev;

void NESAudioFilterSet(Uint filter)
{
	naf_type = filter;
	naf_prev = 0x8000;
}

void NESAudioRender(Int16 *bufp, Uint buflen)
{
	NES_AUDIO_HANDLER *ph;
	Int32 accum;
	Uint32 output;
	
	while (buflen--)
	{
		accum=0;
		for (ph = nah; ph; ph = ph->next)
			accum+=ph->Proc();

		accum += (0x8000 << SHIFT_BITS);

		if (accum < 0)
			output = 0;
		else if (accum > (0x10000 << SHIFT_BITS) - 1)
			output = (0x10000 << SHIFT_BITS) - 1;
		else
			output = accum;
		output >>= SHIFT_BITS;

		switch (naf_type)
		{
			case NES_AUDIO_FILTER_LOWPASS:
				{
					Uint32 prev = naf_prev;
					naf_prev = output;
					output = (output + prev) >> 1;
					naf_prev = output;
				}
				break;
			/*
			case NES_AUDIO_FILTER_WEIGHTED:
				{
					Uint32 prev = naf_prev[ch];
					naf_prev[ch] = output[ch];
					output[ch] = (output[ch] + output[ch] + output[ch] + prev) >> 2;
				}
				break;*/
		}
		*bufp++ = ((Int32)output) - 0x8000;
	}
}

void NESVolume(Uint volume)
{
	NES_VOLUME_HANDLER *ph;
	for (ph = nvh; ph; ph = ph->next) ph->Proc(volume);
}

static void NESAudioHandlerInstallOne(NES_AUDIO_HANDLER *ph)
{
	/* Add to tail of list*/
	ph->next = 0;
	if (nah)
	{
		NES_AUDIO_HANDLER *p = nah;
		while (p->next) p = p->next;
		p->next = ph;
	}
	else
	{
		nah = ph;
	}
}
void NESAudioHandlerInstall(NES_AUDIO_HANDLER *ph)
{
	for (;(ph->fMode&2)?(!!ph->Proc2):(!!ph->Proc);ph++) NESAudioHandlerInstallOne(ph);
}
void NESVolumeHandlerInstall(NES_VOLUME_HANDLER *ph)
{
	for (;ph->Proc;ph++)
	{
		/* Add to top of list*/
		ph->next = nvh;
		nvh = ph;
	}
}

void NESAudioHandlerInitialize(void)
{
	nah = 0;
	nvh = 0;
}

void NESAudioFrequencySet(Uint freq)
{
	frequency = freq;
}
Uint NESAudioFrequencyGet(void)
{
	return frequency;
}

void NESAudioChannelSet(Uint ch)
{
	channel = ch;
}
Uint NESAudioChannelGet(void)
{
	return channel;
}

