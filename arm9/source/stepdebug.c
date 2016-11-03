#include <nds.h>
#include "ds_misc.h"
#include "c_defs.h"

extern u32 __nz;
extern u32 __a;
extern u32 __x;
extern u32 __y;
extern u32 __p;
extern unsigned char *__pc;
extern unsigned char * __lastbank;
extern u32 __scanline;
extern u16 __nes_chr_map[];
extern u32* __memmap_tbl[];
extern u32* __rombase;

unsigned int stepinfo[1024];
extern unsigned int *pstep;

unsigned char ptbuf[1024] = 
/*1234567890123456789012345678901*/
"frame:         line:            "
"pc:                             "
"A:   X:   Y:   P:   SP:         "
"                                "
"                                "
"                                "
"                                "
"                                "
"                                "
"                                "
"                                "
"                                "
"                                "
"                                "
"                                "
"                                "
"                                "
"                                "
"                                "
"                                "
"                                "
"                                "
"                                "
"                                "
;

void shex(unsigned char *p,int d,int n) {
	u16 c;
	do {
		c=d&0x0f;
		if(c<10) c+='0';
		else c=c-10+'A';
		d>>=4;
		p[n--]=c;
	} while(n>=0);
}

#define shex8(a,b) shex(a,b,1)
#define shex16(a,b) shex(a,b,3)
#define shex24(a,b) shex(a,b,5)
#define shex32(a,b) shex(a,b,7)


void stepdebug()
{ 
	static int framecount = 0;
	static int line, keys, oldkeys, opcount = 0;
	unsigned int i, count;
	i = 0;
	opcount++;
	if(line == 240 && __scanline == 241) {
		framecount++;
		swiWaitForVBlank();
		//keys = IPC_KEYS;
		keys &= ~KEY_SELECT;
	}
	if(keys & KEY_SELECT) {
		line = __scanline;
		//pstep = stepinfo;
		return;
	}
	if(keys & KEY_R && line == __scanline) {
		return;
	}
	line = __scanline;
	shex32(ptbuf + 6, framecount);
	shex16(ptbuf + 20, __scanline);
	shex16(ptbuf + 32 + 3, __pc - __lastbank);
	shex8(ptbuf + 32 + 8, *__pc);
	shex8(ptbuf + 32 + 11, *(__pc + 1));
	shex8(ptbuf + 32 + 14, *(__pc + 2));
	shex32(ptbuf + 50, opcount);
	
	shex8(ptbuf + 64 + 2, __a>>24);
	shex8(ptbuf + 64 + 7, __x>>24);
	shex8(ptbuf + 64 + 12, __y>>24);
	shex8(ptbuf + 64 + 17, __p);
	
	for(i = 0; i < 8; i++) {
		shex8(ptbuf + 96 + 3*i, __nes_chr_map[i]);
	}
	for(i = 0; i < 4; i++) {
		shex8(ptbuf + 128 + 3*i, __nes_chr_map[i + 8]);
	}
	for(i = 4; i < 8; i++) {
		shex8(ptbuf + 128 + 3*i, ((__memmap_tbl[i] - __rombase) >> 13) + i);
	}
	

	consoletext(0, ptbuf, 0);
	//memset( ptbuf + 192 + count * 8, 32, (18 * 4 - count) * 8);
	
	do {
		IPC_KEYS = keysCurrent();
		keys = IPC_KEYS;
		if(keys & oldkeys & (KEY_SELECT | KEY_R | KEY_L)) {
			//pstep = stepinfo;
			return;
		}
		if(keys & (KEY_SELECT | KEY_R | KEY_L)) {
			//pstep = stepinfo;
			break;
		}
		swiWaitForVBlank();
		oldkeys = 0;
	}
	while(1);
	oldkeys = keys;
	//pstep = stepinfo;
}
