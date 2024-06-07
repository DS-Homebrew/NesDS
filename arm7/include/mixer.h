#ifndef MIXER_H__
#define MIXER_H__

#include <nds/system.h>
#include "nestypes.h"

#ifdef __cplusplus
extern "C" {
#endif

// Buffer for PCM samples
#define MIXBUFSIZE                      512

// DS output Frequency after mixing is 32.768 kHz 10 bits, this should be equal or below.
#define MIXFREQ                        (32768) //32700 // 32000

//Temporary Define for tests, RAW PCM Channel only works fine with this frequency for some unknown reason
#define RAW_PCM_FREQ                   (24064) //Matches the NES cycle freq

//Matches the NES Base Cycles
#define NES_SAMPLE_RATE                (96000) //24064

// FROM GBATEK: Nintendo DS Audio Bus Clock Frequency = 33.513982MHz/2
#define DS_BUS_CLOCK                   (33513982)

// Proper rounding formula by "Asiekierka" of BlocksDS team https://github.com/blocksds/libnds/pull/49
#define TIMER_FREQ_SHIFT(n, divisor, shift) ((-((DS_BUS_CLOCK >> (shift)) * (divisor)) - ((((n) + 1)) >> 1)) / (n))

// From GBATEK: timerval = -(33513982Hz/2)/freq
#define TIMER_NFREQ                    (TIMER_FREQ_SHIFT(MIXFREQ, 1, 1))



enum AudioFilterType
{
   NES_AUDIO_FILTER_NONE,
   NES_AUDIO_FILTER_CRISP,
   NES_AUDIO_FILTER_LOWPASS,
   NES_AUDIO_FILTER_HIGHPASS,
   NES_AUDIO_FILTER_WEIGHTED,
   NES_AUDIO_FILTER_OLDTV
};


//Pulse Channels 1 and 2
int32_t NESAPUSoundSquareRender1();
int32_t NESAPUSoundSquareRender2();

//Triangle/Noise/DMC Channels
int32_t NESAPUSoundTriangleRender1();
int32_t NESAPUSoundNoiseRender1();
int32_t NESAPUSoundDpcmRender1();

//FDS Channels
int32_t FDSSoundRender();

//VRC Channels
int32_t VRC6SoundRender1();
int32_t VRC6SoundRender2();
int32_t VRC6SoundRender3();

//VRC must be inited to get raw pcm data from ARM9
void VRC6SoundInstall_24();
void VRC6SoundInstall_26();
void FDSSoundInstall();
void readAPU();

#ifdef __cplusplus
}
#endif

#endif /* MIXER_H__ */