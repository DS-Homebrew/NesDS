#ifndef SOUNDIPC_H__
#define SOUNDIPC_H__

#ifdef __cplusplus
extern "C" {
#endif

// To comunicate with ARM7 sound features states
#define FIFO_WRITEPM 		1
#define FIFO_APU_PAUSE 		2
#define FIFO_UNPAUSE 		3
#define FIFO_APU_RESET 		4
#define FIFO_SOUND_RESET 	5
#define FIFO_APU_PAL 	 	6
#define FIFO_APU_NTSC     	7
#define FIFO_APU_SWAP 		8
#define FIFO_APU_NORM 		9
#define FIFO_SOUND_UPDATE	10
#define FIFO_AUDIO_FILTER 	11

#ifdef __cplusplus
}
#endif

#endif /* SOUNDIPC_H__ */