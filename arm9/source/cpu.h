#ifndef CPU_HEADER
#define CPU_HEADER

#ifdef __cplusplus
extern "C" {
#endif

void cpuInit(void);
void EMU_Run(void);
void NSF_Run(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // CPU_HEADER
