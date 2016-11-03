#include <nds.h>
#include <stdio.h>
#include <string.h>
#include "ds_misc.h"
#include "c_defs.h"
#include "menu.h"

int save_slots = 0;
int slots_num = 0;

//a bad idea...
void reg4015interrupt(u32 msg, void *none)
{
	if(msg&0xFF00) {
		IPC_APUIRQ = 1;								//This value is cleared when read.
	}
	IPC_REG4015 = msg&0xFF;							//Indicates that apu status is changed.
}

/*****************************
* name:			writeAPU
* function:		write a val | addr to soundbuff.
* argument:		val: no known
			addr: no known
* description:		none
******************************/
void writeAPU(u32 val,u32 addr) 
{
	if(IPC_APUW - IPC_APUR < 256 && addr != 0x4011 && 
			((addr > 0x8000 && (debuginfo[16] == 24 || debuginfo[16] == 26)) ||
			(addr < 0x4018 || debuginfo[16] == 20))) {
		fifoSendValue32(FIFO_USER_07,(addr << 8) | val);
		IPC_APUW++;
	}
	if(addr == 0x4011) {
		unsigned char *out = IPC_PCMDATA;
		out[__scanline] = val | 0x80;
		*(IPC_APUWRITE + (addr & 0xFF)) = 0x100 | val;
	}
}

/*****************************
* name:			Sound_reset
* function:		tell ARM7 to reset sound.
* argument:		none
* description:		none
******************************/
void Sound_reset() {
	fifoSendValue32(FIFO_USER_08, FIFO_APU_RESET);
}

int last_x, last_y;	//most recently touched coords
int touchstate=1; 	// <2=pen up, 2=first touch, 3=pen down, 4=pen released

/*****************************
* name:			touch_update
* function:		update touchscreen state.
* argument:		none
* description:		used in menu.
******************************/
void touch_update() {
	int ts=touchstate;
	touchPosition touch;
	touchRead(&touch);
	if(IPC_KEYS & KEY_TOUCH) {
		last_x=touch.px;
		IPC_TOUCH_X=touch.px;
		last_y=touch.py;
		IPC_TOUCH_Y=touch.py;
		if(ts<3)
			ts++;
	} else {
		if(ts==2 || ts==3)
			ts=4;
		else
			ts=1;
	} 
	touchstate=ts;
}

/*****************************
* name:			touch_update
* function:		print touchable strings. return string number if it's being touched, or -1 if not
* argument:		ts: a pointer to struct. tells position of text showed.
			pushstate: 1 for touched (shows that the string can be touched, 1 bit for 1 char)
				   0 for none
* description:		used in menu.called by every string in one frame.
******************************/
int do_touchstrings(touchstring *ts, int pushstate) {
	char *str;
	int color, offset, xmin, xmax, ymin, ymax, strnum, strtouched;
	strnum=0;
	strtouched=-1;
	do {
		str=ts->str;
		offset=ts->offset;
		color=(pushstate&1) ? 0x2000:0x1000;
		pushstate>>=1;
		
		if(touchstate>1) {
			xmin=((offset&0x3f)<<2)-4;
			xmax=xmin+(strlen(str)<<3)+8;
			ymin=((offset&~0x3f)>>3)-4;
			ymax=ymin+16;
//			if(initial_x>=xmin && initial_x<xmax && initial_y>=ymin && initial_y<ymax) {
				if(last_x>=xmin && last_x<xmax && last_y>=ymin && last_y<ymax) {
					strtouched=strnum;
					color=0x2000;
//					if(touchstate==3) {
//						strtouched|=0x80000000;
//					}
				}
//			}
		}
		consoletext(offset,str,color);
		
		ts++;
		strnum++;
	} while(ts->offset>=0);
	return strtouched;
}

/*****************************
* name:			load_sram
* function:		load the xxxnes.sav to sram. not realtime saving state.
* argument:		none
* description:		used in emulation.
******************************/
void load_sram() {
	FILE *f;
	
	//if(!(__cartflags&SRAM)) return;		//some games have bad headers.
	if(!active_interface) return;

	romfileext[0]='s';
	romfileext[1]='a';
	romfileext[2]='v';
	romfileext[3]=0;
	f=fopen(romfilename,"r");
	if(!f) return;
	fread((u8*)NES_SRAM,1,0x2000,f);
	fclose(f);
}

/*****************************
* name:			save_sram
* function:		write SRAM to device. not realtime saving state.
* argument:		none
* description:		used in emulation.
******************************/
void save_sram() {
	FILE *f;

	//if(!(__cartflags&SRAM)) return;		//some games have bad headers.
	if(!active_interface) return;

	romfileext[0]='s';
	romfileext[1]='a';
	romfileext[2]='v';
	romfileext[3]=0;
	f=fopen(romfilename,"w");
	if(!f) return;
	fwrite((u8*)NES_SRAM,1,0x2000,f);
	fflush(f);
	fclose(f);
}

/*****************************
* name:			write_savestate
* function:		write realtime saving to xxxnes.ss.
* argument:		num-> slots number
* description:		none
******************************/
void write_savestate(int num) {
	FILE *f;
	u8 *p=(u8*)freemem_start;

	if(!active_interface) return;

	if(num > 9 || num < 0)
		return;

	romfileext=strrchr(romfilename,'.')+1;
	romfileext[0]='s';
	romfileext[1]='s';
	romfileext[2]='0' + num;
	savestate((u32)p);
	f=fopen(romfilename,"w");
	if(!f) return;
	fwrite(p,1,SAVESTATESIZE,f);
	fflush(f);
	fclose(f);						//something maybe lost if we shutdown our DS immi...
	recorder_reset();
}

/*****************************
* name:			read_savestate
* function:		read realtime saving from xxxnes.ss.
* argument:		num-> slots number
* description:		none
******************************/
void read_savestate(int num) {
	FILE *f;
	int i;
	u8 *p=(u8*)freemem_start;

	if(!active_interface) return;

	if(num > 9 || num < 0)
		return;

	romfileext=strrchr(romfilename,'.')+1;		//make sure everything is ok...
	romfileext[0]='s';
	romfileext[1]='s';
	romfileext[2]='0' + num;

	f=fopen(romfilename,"r");
	if(!f) return;
	i=fread(p,1,SAVESTATESIZE,f);
	fclose(f);
	if(i==SAVESTATESIZE)
		loadstate((u32)p);
	recorder_reset();
}


/*****************************
* name:			do_shortcuts
* function:		use buttons instead of 'touch' to do some works.
* argument:		none
* description:		none
******************************/
extern int ad_scale, ad_ypos;
extern int subscreen_stat;
int screen_swap = 0;
int shortcuts_tbl[32] = {0,0,0,0,0,0,0,0,0,0,0, KEY_R|KEY_UP, KEY_R|KEY_LEFT, KEY_R|KEY_DOWN, KEY_R|KEY_RIGHT};
char gestures_tbl[32][32];
int time_tbl[32] = {120, 120, 0, 120, 120, 0, 0, 0, 0, 120, 120, 120, 120, 120, 120, 120, 60, 0, 0};
int container_tbl[32] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1};

int do_gesture_type = -1;
void do_shortcuts()
{
	static int count = 0;
	int i;
	int keys = IPC_KEYS;
	if(keys != 0) {
		for(i = 0; i < MAX_SC; i++) {
			if(! container_tbl[i]) {
				if((keys == shortcuts_tbl[i] && count > time_tbl[i]) || do_gesture_type == i) {
					do_quickf(i);
					do_gesture_type = -1;
					count = 0;
				}
			}
			else {
				if(shortcuts_tbl[i] && (! ((~keys) & shortcuts_tbl[i])) && count > time_tbl[i]) {
					do_quickf(i);
					count = 0;
				}
			}
		}
	}
	count++;
	if(count > 1000)
		count = 1000;
}

void do_quickf(int func)
{
	switch(func) {
	case 0:
		read_savestate(slots_num);
		break;
	case 1:
		write_savestate(slots_num);
		break;
	case 2:
		__emuflags &= ~LIGHTGUN;
		do_rommenu();
		break;
	case 3:
		joyflags^=B_A_SWAP;
		break;
	case 4:
		__emuflags^=AUTOSRAM;
		menu_stat = 1;
		menu_draw = 0;
		save_sram();
		break;
	case 5:
		ad_scale+=0x100;
		rescale(ad_scale,ad_ypos);
		break;
	case 6:
		ad_scale-=0x100;
		rescale(ad_scale,ad_ypos);
		break;
	case 7:
		ad_ypos+=0x10000;
		rescale(ad_scale,ad_ypos);
		break;
	case 8:
		ad_ypos-=0x10000;
		rescale(ad_scale,ad_ypos);
		break;
	case 9:
		__emuflags^=SPLINE;
		menu_stat = 1;
		menu_draw = 0;
		break;
	case 10:
		{
			int tmp;
			tmp = (__emuflags+1)&3;
			__emuflags=(__emuflags&~3)|tmp;
			menu_stat = 1;
			menu_draw = 0;
		}
		break;
	case 11:
		if(debuginfo[16] == 20) {		//16 = MAPPER
			fdscmdwrite(0);
		}
		break;
	case 12: 
		if(debuginfo[16] == 20) {
			fdscmdwrite(1);
		}
		break;
	case 13:
		if(debuginfo[16] == 20) {
			fdscmdwrite(2);
		}
		break;
	case 14:
		if(debuginfo[16] == 20) {
			fdscmdwrite(3);
		}
		break;
	case 15:
		{
			if(!(__emuflags & LIGHTGUN))
				__emuflags ^= SCREENSWAP;
		}
		break;
	case 16:
		{
			__emuflags &= ~LIGHTGUN;
			__emuflags &= ~SCREENSWAP;
		}
		break;
	case 17:
		{
			__emuflags |= FASTFORWARD;
		}
		break;
	case 18:
		{
			__emuflags |= REWIND;
		}
		break;
	default:
		break;
	}
}


char *ishortcuts[] = {
"sc_loadstate",
"sc_savestate",
"sc_loadrom",
"sc_swapab",
"sc_autosramsave",
"sc_scaleleft",
"sc_scaleright",
"sc_scaleup",
"sc_scaledown",
"sc_swaprender",
"sc_swapblend",
"sc_diska",
"sc_diskb",
"sc_diskc",
"sc_diskd",
"sc_swapscreen",
"sc_lightgunoff",
"sc_fastforward",
"sc_rewind",
};

char *igestures[] = {
"ge_loadstate",
"ge_savestate",
"ge_loadrom",
"ge_swapab",
"ge_autosramsave",
"ge_scaleleft",
"ge_scaleright",
"ge_scaleup",
"ge_scaledown",
"ge_swaprender",
"ge_swapblend",
"ge_diska",
"ge_diskb",
"ge_diskc",
"ge_diskd",
"ge_swapscreen",
"ge_lightgunoff",
"ge_fastforward",
"ge_rewind",
};

char *hshortcuts[] = {
"Load from a state",
"Save to a state",
"Show the rom menu",
"Swap the functions of A/B",
"Auto save SRAM",
"Scale left",
"Scale right",
"Scale up",
"Scale down",
"Switch rendering method",
"Switch blend type",
"FDS: Switch to DISK A",
"FDS: Switch to DISK B",
"FDS: Switch to DISK C",
"FDS: Switch to DISK D",
"Swap the top/sub screens",
"Disable LightGun to use menu.",
"Fast forward.",
"Rewind.",
};

char *keystrs[] = {
"KEY_A",
"KEY_B",
"KEY_SELECT",
"KEY_START",
"KEY_RIGHT",
"KEY_LEFT",
"KEY_UP",
"KEY_DOWN",
"KEY_RBUTTON",
"KEY_LBUTTON",
"KEY_X",
"KEY_Y"
};

void rescale(int a, int b)
{
	if(b >= 0)
		REG_BG3Y = -(b >> 8);
	else 
		REG_BG3Y = ((-b) >> 8);
	if(__emuflags & ALLPIXEL) {
		int pos = b / (1 << 16);
	
		if(pos < -(240 - 192)/2) {
			__emuflags |= SCREENSWAP;
			all_pix_start = 0;
			all_pix_end = 1 - pos;
			lcdMainOnBottom();
			REG_BG3Y_SUB = (-(192 + pos)) << 8;
		} else {
			__emuflags &= ~SCREENSWAP;
			all_pix_start = 192 - pos;
			if(all_pix_start > 239)
				all_pix_start = 239;
			all_pix_end = 240;
			lcdMainOnTop();
			REG_BG3Y_SUB = 0;
		}

		ad_scale = 0x10000;
		a = ad_scale;
		REG_BG3PD = 256;
		REG_BG3Y = (-pos) << 8;

		REG_BG3PA_SUB = 256;
		REG_BG3PD_SUB = 256;
	}
	rescale_nr(a, b);
}

void debugwrite_c(int val, int addr)
{
	char buf[64];
	sprintf(buf, "addr:%04X, val:%02X\n", addr, val);
	nocashMessage(buf);
}
