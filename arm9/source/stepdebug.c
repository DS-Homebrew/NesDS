#include <nds.h>
#include "c_defs.h"
#include "NesMachine.h"

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
{/* 
	static int frameCount = 0;
	static int line, keys, oldkeys, opCount = 0;
	unsigned int i, count;
	i = 0;
	opCount++;
	if(line == 240 && __scanline == 241) {
		frameCount++;
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
	shex32(ptbuf + 6, frameCount);
	shex16(ptbuf + 20, __scanline);
	shex16(ptbuf + 32 + 3, rp2A03.m6502.regPc - rp2A03.m6502.lastBank);
	shex8(ptbuf + 32 + 8, *rp2A03.m6502.regPc);
	shex8(ptbuf + 32 + 11, *(rp2A03.m6502.regPc + 1));
	shex8(ptbuf + 32 + 14, *(rp2A03.m6502.regPc + 2));
	shex32(ptbuf + 50, opCount);

	shex8(ptbuf + 64 + 2, rp2A03.m6502.regA>>24);
	shex8(ptbuf + 64 + 7, rp2A03.m6502.regX>>24);
	shex8(ptbuf + 64 + 12, rp2A03.m6502.regY>>24);
	shex8(ptbuf + 64 + 17, rp2A03.m6502.cycles);

	for(i = 0; i < 8; i++) {
		shex8(ptbuf + 96 + 3*i, globals.ppu.nesChrMap[i]);
	}
	for(i = 0; i < 4; i++) {
		shex8(ptbuf + 128 + 3*i, globals.ppu.nesChrMap[i + 8]);
	}
	for(i = 4; i < 8; i++) {
		shex8(ptbuf + 128 + 3*i, ((rp2A03.m6502.memTbl[i] - globals.romBase) >> 13) + i);
	}

	count = pstep - stepinfo;
	if(count > 18 * 4) {
		count = 18 * 4;
	}
	for(i = 0; i < count; i++) {
		shex(ptbuf + 192 + i*8, stepinfo[i] >> 12, 3);
		if(stepinfo[i] & 0x100) {
			*(ptbuf + 192 + i * 8 + 4) = 'w';
		} else {
			*(ptbuf + 192 + i * 8 + 4) = 'r';
		}
		shex(ptbuf + 197 + i*8, stepinfo[i], 1);
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
	//pstep = stepinfo;*/
}
