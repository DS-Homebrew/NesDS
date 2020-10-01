#ifndef arm7snd
#define arm7snd
#define MIXFREQ 0x5e00
#define MIXBUFSIZE 128
#endif


#ifdef __cplusplus
extern "C"{
#endif

extern volatile s16 buffer[MIXBUFSIZE*20];

extern u32 interrupts_to_wait_arm7;
extern int ipc_region;
extern void soundinterrupt(void);

extern int pcmpos;
extern int APU_paused;

extern void readAPU(void);
extern void resetAPU(void);
extern void dealrawpcm(unsigned char *out);


#ifdef __cplusplus
}
#endif
