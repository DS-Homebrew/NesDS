#include "handler.h"
#include "nsf6502.h"

/* --------------- */
/*  Reset Handler  */
/* --------------- */

static NES_RESET_HANDLER *(nrh[0x10]) = { 0, };
void NESReset(void)
{
	NES_RESET_HANDLER *ph;
	Uint prio;
	for (prio = 0; prio < 0x10; prio++) {
		for (ph = nrh[prio]; ph; ph = ph->next) ph->Proc();
	}
}
static void InstallPriorityResetHandler(NES_RESET_HANDLER *ph)
{
	Uint prio = ph->priority;
	if (prio > 0xF) prio = 0xF;
	/* Add to tail of list*/
	ph->next = 0;
	if (nrh[prio])
	{
		NES_RESET_HANDLER *p = nrh[prio];
		while (p->next) p = p->next;
		p->next = ph;
	}
	else
	{
		nrh[prio] = ph;
	}
}
void NESResetHandlerInstall(NES_RESET_HANDLER *ph)
{
	for (; ph->Proc; ph++) InstallPriorityResetHandler(ph);
}
static void NESResetHandlerInitialize(void)
{
	Uint prio;
	for (prio = 0; prio < 0x10; prio++) nrh[prio] = 0;
}


/* ------------------- */
/*  Terminate Handler  */
/* ------------------- */
static NES_TERMINATE_HANDLER *nth = 0;
void NESTerminate(void)
{
	NES_TERMINATE_HANDLER *ph;
	for (ph = nth; ph; ph = ph->next) ph->Proc();
	NESHandlerInitialize();
}
void NESTerminateHandlerInstall(NES_TERMINATE_HANDLER *ph)
{
	/* Add to head of list*/
	ph->next = nth;
	nth = ph;
}
static void NESTerminateHandlerInitialize(void)
{
	nth = 0;
}


void NESHandlerInitialize(void)
{
	NESResetHandlerInitialize();
	NESTerminateHandlerInitialize();
}
