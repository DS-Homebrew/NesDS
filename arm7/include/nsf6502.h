#ifndef NSF6502_H__
#define NSF6502_H__

#include "handler.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef Uint (__fastcall *READHANDLER)(Uint a);
typedef void (__fastcall *WRITEHANDLER)(Uint a, Uint v);

typedef struct NES_READ_HANDLER_TAG {
	Uint min;
	Uint max;
	READHANDLER Proc;
	struct NES_READ_HANDLER_TAG *next;
} NES_READ_HANDLER;

typedef struct NES_WRITE_HANDLER_TAG {
	Uint min;
	Uint max;
	WRITEHANDLER Proc;
	struct NES_WRITE_HANDLER_TAG *next;
} NES_WRITE_HANDLER;

void NESMemoryHandlerInitialize(void);
void NESReadHandlerInstall(NES_READ_HANDLER *ph);
void NESWriteHandlerInstall(NES_WRITE_HANDLER *ph);

Uint NSF6502Install(void);
Uint NES6502GetCycles(void);
void NES6502Irq(void);
Uint NES6502ReadDma(Uint A);
Uint NES6502Read(Uint A);
void NES6502Write(Uint A, Uint V);


#ifdef __cplusplus
}
#endif

#endif /* NSF6502_H__ */
