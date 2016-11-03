#include <nds.h>
#include "ds_misc.h"
#include "c_defs.h"

extern u32 agb_bg_map[];
extern u16 __nes_chr_map[];
u32 debuginfo[48];
char *debugtxt[]={
"ERR0","ERR1","READ","WRITE","BRK","BAD OP","VBLS","FPS",
"BGMISS","cartflg","a","b","c","ALIVE","TMP0","TMP1",
"mapper#", "PRGCRC", "diskno", "makeid", "gameid", "emuflag"};
#define DLINE 4
extern char *__memmap_tbl[];
extern char *__rombase;

extern int shortcuts_tbl[];
extern char *ishortcuts[];

char *fdsdbg[]={
"ienable", "irepeat", "ioccur", "itran",
"denable", "senable", "RWstart", "RWmode",
"motormd", "eject", "ready", "reset",
"faccess", "side", "mountct", "itype",
"startupf", "Throttle",
"Thtime", "disk", "disk_w", "icount",
"ilatch", "bpoint", "bmode", "fsize",
"famount", "point", "sttimer", "sktimer",
"diskno", "makerid", "gameid",
};

int debugdump() {
/*
	int i;
	u32 *p;
	char **cc;

	debuginfo[13]=IPC_ALIVE;
	debuginfo[14]=IPC_TMP0;
	debuginfo[15]=IPC_TMP1;
	
	p=debuginfo;
	cc=debugtxt;
	for(i=64*DLINE;i<64*(DLINE+16);i+=64) {
		consoletext(i,*cc++,0);
		hex32(i+14,*p++);
	}

	p=agb_bg_map;
	for(i=64*DLINE;i<64*(DLINE+16);i+=64) {
		hex32(i+32,*p++);
	}
	
	hex32(64*22,freemem_end-freemem_start);
	consoletext(64*22+18,"bytes free",0);
	consoletext(64*23,"Built",0);
	consoletext(64*23+12,__TIME__,0);
	consoletext(64*23+30,__DATE__,0);
*/

	int i;/*
	static int count = 0;
	if(count++ != 20)
		return 0;*/

	debuginfo[21] = __emuflags;
	if(1 && (__emuflags & NSFFILE)) {
		u32 *ip=(u32*)&mapperstate;
		consoletext	(64 * 4 + 0 * 32, "version", 0);
		hex8		(64 * 4 + 0 * 32 + 18, nsfheader.Version);
		consoletext	(64 * 4 + 1 * 32, "startson", 0);
		hex8		(64 * 4 + 1 * 32 + 18, nsfheader.StartSong);
		consoletext	(64 * 4 + 2 * 32, "totalsong", 0);
		hex8		(64 * 4 + 2 * 32 + 18, nsfheader.TotalSong);
		consoletext	(64 * 4 + 3 * 32, "LoadAddr", 0);
		hex16		(64 * 4 + 3 * 32 + 18, nsfheader.LoadAddress);
		consoletext	(64 * 4 + 4 * 32, "InitAddr", 0);
		hex16		(64 * 4 + 4 * 32 + 18, nsfheader.InitAddress);
		consoletext	(64 * 4 + 5 * 32, "PlayAddr", 0);
		hex16		(64 * 4 + 5 * 32 + 18, nsfheader.PlayAddress);
		for(i=0;i<10;i++) {
			hex32(64*7+i*32,ip[i]);
		}
		
		consoletext	(64 * 16 + 0 * 32, "songno", 0);
		hex16		(64 * 16 + 0 * 32 + 18, __nsfsongno);
		consoletext	(64 * 16 + 1 * 32, "songmode", 0);
		hex16		(64 * 16 + 1 * 32 + 18, __nsfsongmode);
		consoletext	(64 * 16 + 2 * 32, "play", 0);
		hex16		(64 * 16 + 2 * 32 + 18, __nsfplay);
		consoletext	(64 * 16 + 3 * 32, "init", 0);
		hex16		(64 * 16 + 3 * 32 + 18, __nsfinit);

		
		for(i = 0; i < 4; i++) {
			hex32(64 * 20 + i * 32, (u32)__memmap_tbl[i + 4] + 0x2000 * i + 0x8000);
		}
	} else if(debuginfo[16] == 20) {
		u8 *p=(u8*)&mapperstate;//0x7000000;
		u32 *ip=(u32*)&mapperstate;//0x7000000;
		for(i=0;i<18;i++) {
			consoletext(64 * 4 + i * 32, fdsdbg[i], 0);
			hex8(64*4+i*32 + 18,p[i]);
		}
		for(i=6;i<19;i++) {
			consoletext(64*12 + (i-6) * 32, fdsdbg[i + 12], 0);
			hex32(64*12 + (i-6) * 32 + 16,ip[i]);
		}
	}
	else {
		for(i = 0; i < 22; i++) {
			consoletext(64 * 4 + i * 32, debugtxt[i], 0);
			hex32(64 * 4 + i * 32 + 14, debuginfo[i]);
		}
#if 1
		for(i = 0; i < 8; i++) {
			hex(64 * 15 + i * 8, __nes_chr_map[i], 2);
		}
		for(i = 0; i < 4; i++) {
			hex(64 * 16 + i * 8, (__memmap_tbl[i + 4] - __rombase)/0x2000 + i + 4, 2);
		}
#endif
#if 1
		for (i = 0;i < 96; i++)
		{
			hex8(64*17 + i*8, mapperstate[i]);
		}
#endif
	}
	return 0;
}
