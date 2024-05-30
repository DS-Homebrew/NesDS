#ifndef MIXER_H__
#define MIXER_H__

#include <nds/system.h>
#include "nestypes.h"

#ifdef __cplusplus
extern "C" {
#endif

// Buffer for PCM samples
#define MIXBUFSIZE                      128

// DS output Frequency after mixing is 32.768 kHz 10 bits, this should be equal or below.
#define MIXFREQ                        (32768)

//Matches the NES Base Cycles
#define NES_MIXFREQ                    (24064)

// FROM GBATEK: Nintendo DS Audio Bus Clock Frequency = 33.513982MHz/2
#define DS_BUS_CLOCK                   (33513982)  

// Proper rounding formula by "Asiekierka" of BlocksDS team https://github.com/blocksds/libnds/pull/49
#define TIMER_FREQ_SHIFT(n, divisor, shift) ((-((DS_BUS_CLOCK >> (shift)) * (divisor)) - ((((n) + 1)) >> 1)) / (n))

enum
{
   NES_AUDIO_FILTER_NONE,
   NES_AUDIO_FILTER_CRISP,
   NES_AUDIO_FILTER_LOWPASS,
   NES_AUDIO_FILTER_HIGHPASS,
   NES_AUDIO_FILTER_WEIGHTED
};

int SetTmrFreq(void);

#ifdef __cplusplus
}
#endif

#endif /* MIXER_H__ */