#include "s_vrc6.h"

VRC6SOUND vrc6s;

Uint32 DivFix(Uint32 p1, Uint32 p2, Uint32 fix)
{
	Uint32 ret;
	ret = p1 / p2;
	p1  = p1 % p2;
	//p1 = p1 - p2 * ret;
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

void VRC6SoundSquareReset(VRC6_SQUARE *ch)
{
	XMEMSET(ch, 0, sizeof(VRC6_SQUARE));
		if(getApuCurrentRegion() == PAL)
	{
		ch->cps = DivFix((NES_BASECYCLES << 1), 13 * (NESAudioFrequencyGet() << 1), CPS_SHIFT);
	}
	else
	{
		ch->cps = DivFix(NES_BASECYCLES, 12 * NESAudioFrequencyGet(), CPS_SHIFT);
	}
}

void __fastcall VRC6SoundSawReset(VRC6_SAW *ch)
{
	XMEMSET(ch, 0, sizeof(VRC6_SAW));
	if(getApuCurrentRegion() == PAL)
	{
		ch->cps = DivFix((NES_BASECYCLES << 1), 26 * (NESAudioFrequencyGet() << 1), CPS_SHIFT);
	}
	else
	{
		ch->cps = DivFix(NES_BASECYCLES, 24 * NESAudioFrequencyGet(), CPS_SHIFT);
	}
}

void __fastcall VRC6SoundReset(void)
{
	XMEMSET(&vrc6s, 0, sizeof(VRC6SOUND));
	VRC6SoundSquareReset(&vrc6s.square[0]);
	VRC6SoundSquareReset(&vrc6s.square[1]);
	VRC6SoundSawReset(&vrc6s.saw);
}