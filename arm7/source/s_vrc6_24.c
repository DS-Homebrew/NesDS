#include "s_vrc6.h"

//WE CAN'T swap Konami VRC6 regs at runtime, each
//VRC6 mapper needs to have their own audio render engine.

// (:::) VRC6 MAPPER 24 AUDIO ENGINE (:::) //

static Int32 VRC6SoundSquareRender_24(VRC6_SQUARE *ch)
{
	Uint32 output;
	if (ch->update)
	{
		if (ch->update & (2 | 4))
		{
			ch->spd = (((ch->regs[2] & 0x0F) << 8) + ch->regs[1] + 0) << CPS_SHIFT;
		}
		ch->update = 0;
	}

	if (!ch->spd) return 0;

	ch->cycles -= ch->cps;
	while (ch->cycles < 0)
	{
		ch->cycles += ch->spd;
		ch->adr++;
	}
	ch->adr &= 0xF;

	if (ch->mute || !(ch->regs[2] & 0x80)) return 0;

	//output = LinearToLog(ch->regs[0] & 0x0F) + vrc6s.mastervolume;
	output = ch->regs[0] & 0x0F;
	if (!(ch->regs[0] & 0x80) && (ch->adr < ((ch->regs[0] >> 4) + 1)))
	{
#if 1
		return 0;	/* and array gate */
#else
		output++;	/* negative gate */
#endif
	}
	//return LogToLinear(output, LOG_LIN_BITS - LIN_BITS - 16 - 1);
	return output;
}

static Int32 VRC6SoundSawRender_24(VRC6_SAW *ch)
{
	if (ch->update)
	{
		if (ch->update & (2 | 4))
		{
			ch->spd = (((ch->regs[2] & 0x0F) << 8) + ch->regs[1] + 0) << CPS_SHIFT;
		}
		ch->update = 0;
	}

	if (!ch->spd) return 0;

	ch->cycles -= ch->cps;
	while (ch->cycles < 0)
	{
		ch->cycles += ch->spd;
		ch->output += (ch->regs[0] & 0x3F);
		if (7 == ++ch->adr)
		{
			ch->adr = 0;
			ch->output = 0;
		}
	}

	if (ch->mute || !(ch->regs[2] & 0x80)) return 0;

	//output = LinearToLog((ch->output >> 3) & 0x1F) + vrc6s.mastervolume;
	//return LogToLinear(output, LOG_LIN_BITS - LIN_BITS - 16 - 1);
	return (ch->output >> 3) & 0x1f;
}

static Int32 __fastcall VRC6SoundRender_24(void)
{
	Int32 accum = 0;
	accum += VRC6SoundSquareRender_24(&vrc6s.square[0]);
	accum += VRC6SoundSquareRender_24(&vrc6s.square[1]);
	accum += VRC6SoundSawRender_24(&vrc6s.saw);
	return accum;
}

int32_t VRC6SoundRender1_24(void)
{
	return VRC6SoundSquareRender_24(&vrc6s.square[0]);
}
int32_t VRC6SoundRender2_24(void)
{
	return VRC6SoundSquareRender_24(&vrc6s.square[1]);
}
int32_t VRC6SoundRender3_24(void)
{
	return VRC6SoundSawRender_24(&vrc6s.saw);
}

static NES_AUDIO_HANDLER s_vrc6_audio_handler_24[] = {
	{ 1, VRC6SoundRender_24, }, 
	{ 0, 0, }, 
};

static void __fastcall VRC6SoundVolume_24(Uint volume)
{
	volume += 64;
	//vrc6s.mastervolume = (volume << (LOG_BITS - 8)) << 1;
}

static NES_VOLUME_HANDLER s_vrc6_volume_handler_24[] = {
	{ VRC6SoundVolume_24, },
	{ 0, }, 
};

void VRC6SoundWrite9000_24(Uint address, Uint value)
{
	vrc6s.square[0].regs[address & 3] = value;
	vrc6s.square[0].update |= 1 << (address & 3); 
}
void VRC6SoundWriteA000_24(Uint address, Uint value)
{
	vrc6s.square[1].regs[address & 3] = value;
	vrc6s.square[1].update |= 1 << (address & 3); 
}
void VRC6SoundWriteB000_24(Uint address, Uint value)
{
	vrc6s.saw.regs[address & 3] = value;
	vrc6s.saw.update |= 1 << (address & 3); 
}

static NES_WRITE_HANDLER s_vrc6_write_handler_24[] =
{
	{ 0x9000, 0x9002, VRC6SoundWrite9000_24, },
	{ 0xA000, 0xA002, VRC6SoundWriteA000_24, },
	{ 0xB000, 0xB002, VRC6SoundWriteB000_24, },
	{ 0,      0,      0, 				  },
};

static NES_RESET_HANDLER s_vrc6_reset_handler_24[] = {
	{ NES_RESET_SYS_NOMAL, VRC6SoundReset, }, 
	{ 0,                   0, }, 
};

void VRC6SoundInstall_24(void)
{
	NESAudioHandlerInstall(s_vrc6_audio_handler_24);
	NESVolumeHandlerInstall(s_vrc6_volume_handler_24);
	NESResetHandlerInstall(s_vrc6_reset_handler_24);
}
