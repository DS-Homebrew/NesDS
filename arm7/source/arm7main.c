#include <nds.h>
#include <string.h>
#include "c_defs.h"
#include "SoundIPC.h"
#include "audiosys.h"
#include "handler.h"
#include "calc_lut.h"
#include "mixer.h"
#include "audio_capture.h"

s16 buffer [MIXBUFSIZE * 20]; // Sound Samples Buffer Size, adjust size if necessary

// Set Flag for the APU settings to match PAL Sound Frequency
enum ApuRegion ApuCurrentRegion = NTSC;

void SetApuPAL()
{
	ApuCurrentRegion = PAL;
}

void SetApuNTSC()
{
	ApuCurrentRegion = NTSC;
}

enum ApuRegion getApuCurrentRegion()
{
	return ApuCurrentRegion;
}

// SWAP CYCLES
enum ApuStatus ApuCurrentStatus = Normal;

void SetApuSwap()
{
	ApuCurrentStatus = Reverse;
}

void SetApuNormal()
{
	ApuCurrentStatus = Normal;
}

enum ApuStatus getApuCurrentStatus()
{
	return ApuCurrentStatus;
}

void readAPU(void);
void resetAPU(void);

// Resets thge APU emulation to avoid garbage sounds
void resetAPU() 
{
	NESReset();
	IPC_APUW = 0;
	IPC_APUR = 0;
}

// Adjust Volume and frequency using a precalculated logarithmic table
static inline short adjust_samples(short sample, int freq_shift, int volume)
{
	if(sample >= 0)
	{
		sample = calc_table[sample << freq_shift];
	} else {
		sample = -calc_table[(-sample) << freq_shift];
	}
	return sample << volume;
}

// Adjust alignment for proper volume and frequency
static inline short adjust_vrc(short sample, int freq_shift)
{
	return sample << freq_shift;
}

// From GBATEK: timerval = -(33513982Hz/2)/freq
int inline SetTmrFreq(void)
{
	int TmrFreq;
		TmrFreq = (TIMER_FREQ_SHIFT(MIXFREQ,1,1));
	return TmrFreq;
}

// Only works well with 24064 sound frequency, needs review
void Raw_PCM_Channel(u8 *buffer)
{
static unsigned char pcm_out = 0x7F;
int pcm_line = 120;
int pcmprevol = 0x3F;	

	u8 *in = IPC_PCMDATA;
	int i;
	int count = 0;
	int line = 0;
	u8 *outp = buffer;

	pcm_line = REG_VCOUNT;

	if(1) 
	{
		for(i = 0; i < MIXBUFSIZE; i++) 
		{
			if(in[pcm_line] & 0x80)
			{
				pcm_out = in[pcm_line] & 0x7F;
				in[pcm_line] = 0;
				count++;
			}
			*buffer++ = (pcm_out + pcmprevol - 0x80);
			pcmprevol = pcm_out;
			line += 100;
			if(line >= 152)
			{
				line -= 152;
				pcm_line++;
				if(pcm_line > 262) 
				{
					pcm_line = 0;
				}
			}
		}
	}
	//not a playable raw pcm.
	if(count < 10) 
	{
		for(i = 0; i < MIXBUFSIZE; i++) 
		{
			*outp++ = 0;
			pcmprevol = 0x3F;
			pcm_out = 0x3F;
		}
	}
}

//----------------------------------------------//
//                                              //
//********SOUND MIXER CHANNELS PARAMETERS*******//
//                                              //
//----------------------------------------------//

static int chan = 0;
int ENBLD = SCHANNEL_ENABLE;
int RPEAT = SOUND_REPEAT;
int FRQ32 = SNDEXTCNT_FREQ_32KHZ;
int FRQ47 = SNDEXTCNT_FREQ_47KHZ;
int PCM_8 = SOUND_FORMAT_8BIT;
int PCM16 = SOUND_FORMAT_16BIT;
int ADPCM = SOUND_FORMAT_ADPCM;

// Ch Volume and Pan Control  // Default Values 0Min ~ 127Max (0x0 ~ 0x7F)
// Max is 0x7F, min is 0x00, defaults are 0x20 - 0x60 for mid panning, 0x40 for center

// Pulse 1
// int def_volume = 0x3F; // Dummy Value

// int Pulse1_volume()
// {
// 	int init_val = SOUND_VOL(0x00);
// 	int P1_VL = init_val + def_volume; // VOL 0x5F
// 	return P1_VL;
// }

int P1_VL = SOUND_VOL(0x41); // VOL 0x5F
int P1_PN = SOUND_PAN(0x20); // PAN 0X20

// Pulse 2
int P2_VL = SOUND_VOL(0x40); // VOL 0x5F
int P2_PN = SOUND_PAN(0x60); // PAN 0X60

// Triangle
int TR_VL = SOUND_VOL(0x7F); // VOL 0x7F
int TR_PN = SOUND_PAN(0x40); // PAN 0X20

// Noise
int NS_VL = SOUND_VOL(0x7A); // VOL 0x7A
int NS_PN = SOUND_PAN(0x45); // PAN 0X45

// DMC
int DM_VL = SOUND_VOL(0x75); // VOL 0x6F
int DM_PN = SOUND_PAN(0x40); // PAN 0x40

// FDS
int F1_VL = SOUND_VOL(0x5F); // VOL 0x7F
int F1_PN = SOUND_PAN(0x40); // PAN 0X40

// VRC6 Square 1
int V1_VL = SOUND_VOL(0x3C); // VOL 0x3C
int V1_PN = SOUND_PAN(0x54); // PAN 0x54

// VRC6 Square 2
int V2_VL = SOUND_VOL(0x3B); // VOL 0x3C
int V2_PN = SOUND_PAN(0x2C); // PAN 0x54

// VRC6 Saw
int V3_VL = SOUND_VOL(0x3C); // VOL 0x3C
int V3_PN = SOUND_PAN(0x40); // PAN 0x54

// Delta PCM Channel
int RP_VL = SOUND_VOL(0x6F); // VOL 0x7F
int RP_PN = SOUND_PAN(0x40); // PAN 0x40

void restartsound(int ch)
{
	chan = ch;

	SCHANNEL_CR(0) = ENBLD |
					RPEAT |
					//Pulse1_volume()|
					P1_VL |
					P1_PN |
					FRQ47 |
					SNDEXTCNT_ENABLE|
					PCM16 ;
	
	SCHANNEL_CR(1) = ENBLD |
					RPEAT |
					P2_VL |
					P2_PN |
					FRQ47 |
					SNDEXTCNT_ENABLE|
					PCM16 ;

	SCHANNEL_CR(2) = ENBLD |
					RPEAT |
					TR_VL |
					TR_PN |
					FRQ47 |
					SNDEXTCNT_ENABLE|
					PCM16 ;

	SCHANNEL_CR(3) = ENBLD |
					RPEAT |
					NS_VL |
					NS_PN |
					FRQ47 |
					SNDEXTCNT_ENABLE|
					PCM16 ;

	SCHANNEL_CR(4) = ENBLD |
					RPEAT |
					DM_VL |
					DM_PN |
					FRQ47 |
					SNDEXTCNT_ENABLE|
					PCM16 ;
	
	SCHANNEL_CR(5) = ENBLD |
					RPEAT |
					F1_VL |
					F1_PN |
					FRQ47 |
					SNDEXTCNT_ENABLE|
					PCM16 ;

	SCHANNEL_CR(6) = ENBLD |
					RPEAT |
					V1_VL |
					V1_PN |
					FRQ47 |
					SNDEXTCNT_ENABLE|
					PCM16 ;
	
	SCHANNEL_CR(7) = ENBLD |
					RPEAT |
					V2_VL |
					V2_PN |
					FRQ47 |
					SNDEXTCNT_ENABLE|
					PCM16 ;
	
	SCHANNEL_CR(8) = ENBLD |
					RPEAT |
					V3_VL |
					V3_PN |
					FRQ47 |
					SNDEXTCNT_ENABLE|
					PCM16 ;

//TODO: Channel 9-11 reserved to mix Konami VCR7 Audio ("Lagrange Point" is the only game that uses this.)
//TODO: Channel 12-13 reserved to mix NAMCO N163 Audio (4 N163 channels per NDS channel)

// Delta PCM // TODO: Move to channel 14
	SCHANNEL_CR(10) = ENBLD |
					RPEAT |
					RP_VL |
					RP_PN |
					FRQ47 |
					SNDEXTCNT_ENABLE|
					PCM16 ;

	TIMER0_CR = TIMER_ENABLE; 
	TIMER1_CR = TIMER_CASCADE | TIMER_IRQ_REQ | TIMER_ENABLE;
}

void stopsound() 
{
	SCHANNEL_CR(0) = 0;
	SCHANNEL_CR(1) = 0;
	SCHANNEL_CR(2) = 0;
	SCHANNEL_CR(3) = 0;
	SCHANNEL_CR(4) = 0;
	SCHANNEL_CR(5) = 0;
	SCHANNEL_CR(6) = 0;
	SCHANNEL_CR(7) = 0;
	SCHANNEL_CR(8) = 0;
	SCHANNEL_CR(10) = 0;
	TIMER0_CR = 0;
	TIMER1_CR = 0;
}

int pcmpos = 0;
int APU_paused = 0;

// Pulse Channels 1 and 2
int32_t NESAPUSoundSquareRender1();
int32_t NESAPUSoundSquareRender2();

// Triangle/Noise/DMC Channels
int32_t NESAPUSoundTriangleRender1();
int32_t NESAPUSoundNoiseRender1();
int32_t NESAPUSoundDpcmRender1();

// FDS Channels
int32_t FDSSoundRender1();
int32_t FDSSoundRender2();
int32_t FDSSoundRender3();

// VRC Channels
int32_t VRC6SoundRender1();
int32_t VRC6SoundRender2();
int32_t VRC6SoundRender3();

// VRC must be inited to get raw pcm data from ARM9
void VRC6SoundInstall();
void FDSSoundInstall();
void readAPU();

//Set Default Filter Type
enum AudioFilterType CurrentFilterType = NES_AUDIO_FILTER_NONE;


//Get New Filter Type from ARM9
void setAudioFilter()
{
	switch (FIFO_AUDIO_FILTER)
	{
	case FIFO_AUDIO_FILTER << 0:
		CurrentFilterType = NES_AUDIO_FILTER_NONE;
		break;
	case FIFO_AUDIO_FILTER << 2:
		CurrentFilterType = NES_AUDIO_FILTER_CRISP;
		break;
	case FIFO_AUDIO_FILTER << 3:
	 	CurrentFilterType = NES_AUDIO_FILTER_OLDTV;
		break;
	case FIFO_AUDIO_FILTER << 4:
		CurrentFilterType = NES_AUDIO_FILTER_LOWPASS;
		break;
	case FIFO_AUDIO_FILTER << 5:
		CurrentFilterType = NES_AUDIO_FILTER_HIGHPASS;
		break;
	case FIFO_AUDIO_FILTER << 6:
		CurrentFilterType = NES_AUDIO_FILTER_WEIGHTED;
		break;

	}
}
// Filter Type Get from Settings
enum AudioFilterType getAudioFilterType()
{
	return CurrentFilterType;
}

//Audio Filters
static inline short PassFilter(short int output, u32 *coef)
{
static short int accum;
	accum = 0;
	switch (CurrentFilterType)
	{
		// Default No Filter
	case NES_AUDIO_FILTER_NONE:
		break;
		//Modern RF TV Filter
	case NES_AUDIO_FILTER_CRISP:
		accum = 0;
		output = (output + (accum << 1));
		accum = output;
		output = accum;
		*coef++ = accum;
		break;
		//Old TV Filter
	case NES_AUDIO_FILTER_OLDTV:
		accum = 0;
		accum = output >> 1;
		*coef++ = accum;
		output = accum << 1;
		*coef++ = output << 1;
		break;
		// Famicom/NES Filter
	case NES_AUDIO_FILTER_LOWPASS:
		accum = 0;
		output = ((output + (accum * 7)) >> 3) << 3;
		accum = *coef++;
		*coef++ = output;
		break;
	case NES_AUDIO_FILTER_HIGHPASS:
		accum = 0;
		*coef++ = (((*coef++ * 8)) + (accum * 7)) >> 3;
		*coef++ = output;
		break;	
	case NES_AUDIO_FILTER_WEIGHTED:
		accum = 0;
		output = (output + output + output + MIXFREQ) >> 2;
		break;
	}
	return output;
}

// Mixer handler TODO: Implement cases for custom sound filters.
void mix(int chan)
{
    int mapper = IPC_MAPPER;
    if (!APU_paused) 
	{
        int i;
        s16 *pcmBuffer = &buffer[chan*MIXBUFSIZE]; // Pointer to PCM buffer

        for (i = 0; i < MIXBUFSIZE; i++)
		{			
			short int input = adjust_samples(NESAPUSoundSquareRender1(), 6, 4);
			short int output = PassFilter(input, pcmBuffer);
			*pcmBuffer++ = output;
        }

		pcmBuffer+=MIXBUFSIZE;
  		for (i = 0; i < MIXBUFSIZE; i++)
 		{
            short int input = adjust_samples(NESAPUSoundSquareRender2(), 6, 4);
			short int output = PassFilter(input, pcmBuffer);
			*pcmBuffer++ = output;
        }

		pcmBuffer+=MIXBUFSIZE;
        for (i = 0; i < MIXBUFSIZE; i++) 
		{
            short int input = adjust_samples(NESAPUSoundTriangleRender1(), 7, 4);
			short int output = PassFilter(input, pcmBuffer);
			*pcmBuffer++ = output;
        }

		pcmBuffer+=MIXBUFSIZE;
        for (i = 0; i < MIXBUFSIZE; i++) 
		{
            short int input = adjust_samples(NESAPUSoundNoiseRender1(), 6, 3);
			short int output = PassFilter(input, pcmBuffer);
			*pcmBuffer++ = output;
        }

		pcmBuffer+=MIXBUFSIZE;
        for (i = 0; i < MIXBUFSIZE; i++) 
		{
            short int input = adjust_samples(NESAPUSoundDpcmRender1(), 4, 5);
			short int output = PassFilter(input, pcmBuffer);
			*pcmBuffer++ = output;
        }

		pcmBuffer+=MIXBUFSIZE;
        if (mapper == 20 || mapper == 256)
		{
            for (i = 0; i < MIXBUFSIZE; i++) 
			{
                short int input = adjust_samples(FDSSoundRender3(), 0, 4);
				short int output = PassFilter(input, pcmBuffer);
				*pcmBuffer++ = output;
            }
		} 
		    else
			{
		    pcmBuffer+=MIXBUFSIZE;
			}

		pcmBuffer+=MIXBUFSIZE;	
        if (mapper == 24 || mapper == 26 || mapper == 256)
		{
            for (i = 0; i < MIXBUFSIZE; i++)
			{
				short int input = (adjust_vrc(VRC6SoundRender1(), 11)) << 1;
				short int output = PassFilter(input, pcmBuffer);
				*pcmBuffer++ = output;
            }

			pcmBuffer+=MIXBUFSIZE;
            for (i = 0; i < MIXBUFSIZE; i++) 
			{
				short int input = (adjust_vrc(VRC6SoundRender2(), 11)) << 1;
				short int output = PassFilter(input, pcmBuffer);
				*pcmBuffer++ = output;
            }

			pcmBuffer+=MIXBUFSIZE;
            for (i = 0; i < MIXBUFSIZE; i++)
			{
				short int input = (adjust_vrc(VRC6SoundRender3(), 10)) << 1;
				short int output = PassFilter(input, pcmBuffer);
				*pcmBuffer++ = output;
            }
        }	
		// Mix everything, including RAW PCM channels.	
		Raw_PCM_Channel((u8 *)&buffer[chan*(MIXBUFSIZE/2) + MIXBUFSIZE*18]);
    }
    readAPU();
    APU4015Reg(); // to refresh reg4015.
}

void initsound()
{ 		
	int i;
	powerOn(BIT(0));
	REG_SOUNDCNT = SOUND_ENABLE | SOUND_VOL(0x72);
	for(i = 0; i < 16; i++) 
	{
		SCHANNEL_CR(i) = 0;
	}

	SCHANNEL_SOURCE(0) = (u32)&buffer[0];
	SCHANNEL_SOURCE(1) = (u32)&buffer[2*MIXBUFSIZE];
	SCHANNEL_SOURCE(2) = (u32)&buffer[4*MIXBUFSIZE];
	SCHANNEL_SOURCE(3) = (u32)&buffer[6*MIXBUFSIZE];
	SCHANNEL_SOURCE(4) = (u32)&buffer[8*MIXBUFSIZE];
	SCHANNEL_SOURCE(5) = (u32)&buffer[10*MIXBUFSIZE];
	SCHANNEL_SOURCE(6) = (u32)&buffer[12*MIXBUFSIZE];
	SCHANNEL_SOURCE(7) = (u32)&buffer[14*MIXBUFSIZE];
	SCHANNEL_SOURCE(8) = (u32)&buffer[16*MIXBUFSIZE];
	SCHANNEL_SOURCE(10) = (u32)&buffer[18*MIXBUFSIZE];

	SCHANNEL_TIMER(0) = SetTmrFreq();
	SCHANNEL_TIMER(1) = SetTmrFreq();
	SCHANNEL_TIMER(2) = SetTmrFreq();
	SCHANNEL_TIMER(3) = SetTmrFreq();
	SCHANNEL_TIMER(4) = SetTmrFreq();
	SCHANNEL_TIMER(5) = SetTmrFreq();
	SCHANNEL_TIMER(6) = SetTmrFreq();
	SCHANNEL_TIMER(7) = SetTmrFreq();
	SCHANNEL_TIMER(8) = SetTmrFreq();
	SCHANNEL_TIMER(10) = SetTmrFreq() << 1;

	SCHANNEL_LENGTH(0) = MIXBUFSIZE;
	SCHANNEL_LENGTH(1) = MIXBUFSIZE;
	SCHANNEL_LENGTH(2) = MIXBUFSIZE;
	SCHANNEL_LENGTH(3) = MIXBUFSIZE;
	SCHANNEL_LENGTH(4) = MIXBUFSIZE;
	SCHANNEL_LENGTH(5) = MIXBUFSIZE;
	SCHANNEL_LENGTH(6) = MIXBUFSIZE;
	SCHANNEL_LENGTH(7) = MIXBUFSIZE;
	SCHANNEL_LENGTH(8) = MIXBUFSIZE;
	SCHANNEL_LENGTH(10) = MIXBUFSIZE >> 1;

	SCHANNEL_REPEAT_POINT(0) = 0;
	SCHANNEL_REPEAT_POINT(1) = 0;
	SCHANNEL_REPEAT_POINT(2) = 0;
	SCHANNEL_REPEAT_POINT(3) = 0;
	SCHANNEL_REPEAT_POINT(4) = 0;
	SCHANNEL_REPEAT_POINT(5) = 0;
	SCHANNEL_REPEAT_POINT(6) = 0;
	SCHANNEL_REPEAT_POINT(1) = 0;
	SCHANNEL_REPEAT_POINT(8) = 0;
	SCHANNEL_REPEAT_POINT(10) = 0;

	TIMER0_DATA = SetTmrFreq() << 1;
	TIMER1_DATA = 0x10000 - MIXBUFSIZE;
	memset(buffer, 0, sizeof(buffer));

	memset(IPC_PCMDATA, 0, 512);
}  

// // Configure Left Channel Capture
// void startSoundCapture0(void *buffer, u16 length) 
// {
//     REG_SNDCAP0DAD = (u32)buffer; // Dirección de destino de la captura
//     REG_SNDCAP0LEN = length;      // Longitud del búfer de captura
//     REG_SNDCAP0CNT = (0 << 1) |   // Capturar del mezclador izquierdo
//                      (0 << 2) |   // Captura en bucle
//                      (0 << 3) |   // Formato PCM16
//                      (1 << 7);    // Iniciar la captura
// }

// // Configure Right Channel Capture
// void startSoundCapture1(void *buffer, u16 length)
// {
//     REG_SNDCAP1DAD = (u32)buffer; // Dirección de destino de la captura
//     REG_SNDCAP1LEN = length;      // Longitud del búfer de captura
//     REG_SNDCAP1CNT = (1 << 1) |   // Capturar del mezclador derecho
//                      (0 << 2) |   // Captura en bucle
//                      (0 << 3) |   // Formato PCM16
//                      (1 << 7);    // Iniciar la captura
// }
// u16 capture_buffer_lenght = sizeof(buffer);
// u16 *pcmBufferCapture = sizeof(buffer)+1;

// Capture Audio for reverb and pseudo-surround effect
// void startSoundCapture0(void *pcmBufferCapture, u16 capture_buffer_lenght);
// void startSoundCapture1(void *pcmBufferCapture, u16 capture_buffer_lenght);

// Stops sound, restarts sound, reset apu, refreshes 4015 reg, clears buffer
void lidinterrupt(void)
{
	stopsound();
	restartsound(1);
}

void soundinterrupt(void)
{
	chan^=1;
	mix(chan);
	if(REG_IF & IRQ_TIMER1)
	{
		lidinterrupt();
		chan = 1;
		REG_IF = IRQ_TIMER1;
	}

}

void APUSoundWrite(Uint address, Uint value);	//from s_apu.c (skip using read handlers, just write it directly)

void fifointerrupt(u32 msg, void *none)			//This should be registered to a fifo channel.
{
	switch(msg&0xff) 
	{
		case FIFO_APU_PAUSE:
			APU_paused=1;
			memset(buffer,0,sizeof(buffer));
			break;
		case FIFO_UNPAUSE:
			APU_paused=0;
			break;
		case FIFO_APU_RESET:
			memset(buffer,0,sizeof(buffer));
			APU_paused=0;
			resetAPU();
			APU4015Reg();
			readAPU();
			break;
		case FIFO_SOUND_RESET:
			lidinterrupt();
			memset(buffer,0,sizeof(buffer));
			break;
		case FIFO_APU_PAL:
			SetApuPAL();
			resetAPU();
			readAPU();
			break;
		case FIFO_APU_NTSC:
			SetApuNTSC();
			resetAPU();
			readAPU();
			break;
		case FIFO_APU_SWAP:
			SetApuSwap();
			resetAPU();
			readAPU();
			break;
		case FIFO_APU_NORM:
			SetApuNormal();
			resetAPU();
			readAPU();
			break;
		case FIFO_SOUND_UPDATE:
			resetAPU();
			readAPU();
			APU4015Reg();
			break; 	
	}
}

void readAPU()
{
	u32 msg;
	if(1) 
	{
		while((msg = fifoGetValue32(FIFO_USER_07)) != 0)
			APUSoundWrite(msg >> 8, msg & 0xFF);
		IPC_APUR = IPC_APUW;
	}
	else 
	{
		unsigned int *src = IPC_APUWRITE;
		unsigned int end = IPC_APUW;
		unsigned int start = IPC_APUR;
		while(start < end) 
		{
			unsigned int val = src[start&(1024 - 1)];
			APUSoundWrite(val >> 8, val & 0xFF);
			start++;
		}
		IPC_APUR = start;
	}
}

void interrupthandler() 
{
	u32 flags=REG_IF&REG_IE;
	if(flags&IRQ_TIMER1)
		soundinterrupt();
}

void nesmain() 
{
	NESAudioFrequencySet(MIXFREQ);
	//NESTerminate();
	//NESHandlerInitialize();
	//NESAudioHandlerInitialize();
	
	// Change func name to "DPCMSoundInstall();"
	APUSoundInstall();
	FDSSoundInstall();
	VRC6SoundInstall();
	
	resetAPU();
	NESVolume(0);

	swiWaitForVBlank();
	initsound();
	restartsound(1);

	fifoSetValue32Handler(FIFO_USER_08, fifointerrupt, 0);		//use the last IPC channel to comm..
	irqSet(IRQ_TIMER1, soundinterrupt);
	//irqSet(IRQ_LID, lidinterrupt);
}
