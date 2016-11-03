#include <nds.h>
#include <fat.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "ds_misc.h"
#include "c_defs.h"
#include "menu.h"

extern u32 agb_bg_map[];

void menu_hide(void)
{
	menu_stat = 0;
	menu_draw = 0;
	hideconsole();
}

void menu_file_loadrom(void)
{
	menu_stat = 0;
	menu_draw = 0;
	menu_depth = 1;
	last_menu = menu_array[0];
	do_rommenu();
}

void menu_file_savestate(void)
{
	menu_stat = 3;
	write_savestate(slots_num);
}

void menu_file_loadstate(void)
{
	menu_stat = 3;
	read_savestate(slots_num);
}

void menu_file_savesram(void)
{
	menu_stat = 3;
	save_sram();
}

void menu_file_slot(void)
{
	if(lastbutton_cnt < 6) {
		if(lastbutton_cnt & 1)
			slots_num--;
		else
			slots_num++;
		if(slots_num < 0)
			slots_num = 9;
		if(slots_num > 9)
			slots_num = 0;
		hex8(64*18 + 4 + 10, slots_num);
	}
	menu_stat = 3;
}

void menu_file_start(void)
{
	consoletext(64*11 + 4, "Stat:", 0);
	consoletext(64*11 + 4 + 10, (__emuflags & AUTOSRAM) ? "Auto" : "Manual" , 0);

	consoletext(64*18 + 4, "Slot:", 0);
	hex8(64*18 + 4 + 10, slots_num);
}

void menu_game_start(void)
{
	consoletext(64*11 + 34, "TIMING:", 0);
	consoletext(64*11 + 48, (__emuflags&PALTIMING)? "PAL ":"NTSC", 0x1000);
	consoletext(64*18 + 24, "ALL:", 0);
	consoletext(64*18 + 32, (__emuflags&ALLPIXELON)? "YES":"NO ", 0x1000);
}

void menu_game_pal(void)
{
	menu_stat = 3;
	__emuflags |= PALTIMING;
	ntsc_pal_reset();
	consoletext(64*11 + 48, "PAL ", 0x1000);
}

void menu_game_ntsc(void)
{
	menu_stat = 3;
	__emuflags &= ~PALTIMING;
	ntsc_pal_reset();
	consoletext(64*11 + 48, "NTSC", 0x1000);
}

void show_all_pixel(void)
{
	menu_stat = 3;
	__emuflags ^= ALLPIXELON;
	if(__emuflags & ALLPIXELON) {
		consoletext(64*18 + 32, "YES", 0x1000);	
	}
	else
		consoletext(64*18 + 32, "NO ", 0x1000);
}


#define P1 (64*7+20)
#define P2 (64*15+20)
#define LOCK 0x40000
char B_btn[]="Y";
char A_btn[]="B";
touchstring controls[]={
	{P1+28,A_btn},{P1+24,B_btn},{P1+14,"\x88"}, {P1+18,"\x88"}, {P1-124,"\x82"}, {P1+132,"\x83"}, {P1,"\x80"}, {P1+8,"\x81"},
	{P2+28,A_btn},{P2+24,B_btn},{P2+14,"\x88"}, {P2+18,"\x88"}, {P2-124,"\x82"}, {P2+132,"\x83"}, {P2,"\x80"}, {P2+8,"\x81"},
	{P1-110,"Enable"},{P2-110,"Enable"},{P1+256-12,"Lock"},{-1,0}};

int menu_touchcontroller() {
	u32 flags, i;

	flags=joyflags;
	if(flags&B_A_SWAP) {
		*B_btn='B';
		*A_btn='A';
	} else {
		*B_btn='Y';
		*A_btn='B';
	}
	if(!(flags&LOCK))
		flags&=~0xffff;
		
	i=do_touchstrings(controls,joystate | (flags&0x70000));
	if(touchstate==4) {
		flags^=1<<i;
	} else {
		if(i<16 && !(flags&LOCK))
			flags|=1<<i;
	}
	
	joyflags=flags;
	return 0;
}

struct button button_game = {
	.name = "Game",
	.x = 11,
	.y = 0,
	.w = 4,
	.h = 1
};

struct button button_intput[] = {
	{
	.name = "\rBA Swap",
	.x = 1,
	.y = 19,
	.w = 7,
	.h = 3
	},
	{
	.name = "\rInc",
	.x = 15,
	.y = 19,
	.w = 3,
	.h = 3
	},
	{
	.name = "\rDec",
	.x = 21,
	.y = 19,
	.w = 3,
	.h = 3
	},
};

void do_top_menu(void)
{
	if(touchstate > 1) {
		if(!(lastbutton != NULL && last_x >= lastbutton->x * 8 + 4 && last_x <= (lastbutton->x + lastbutton->w + 2) * 8 - 3 
			&& last_y >= lastbutton->y * 8 + 4 && last_y <= (lastbutton->y + lastbutton->h + 2) * 8 - 3)) {
			if(lastbutton != NULL) {
				draw_button(lastbutton->name, lastbutton->x, lastbutton->y, lastbutton->w, lastbutton->h, 0);
				lastbutton->stat = 0;
				lastbutton = NULL;
			}
			check_button_group(0);
			check_button_group(2);
		}
	} else if(lastbutton != NULL) {
		draw_button(lastbutton->name, lastbutton->x, lastbutton->y, lastbutton->w, lastbutton->h, 0);
		lastbutton->stat = 0;
		lastbutton = NULL;
	}

	if(lastbutton && touchstate == 4) {
		if(lastbutton_type == 0) {
			if(menu_depth == lastbutton_cnt + 1) { //use this to hide menu
				menu_stat = 0;
				menu_draw = 0;
				hideconsole();
			} else { //change menu depth
				lastbutton->stat = 0;
				lastbutton = NULL;
				menu_depth = lastbutton_cnt + 1;
				last_menu = menu_array[lastbutton_cnt];
				menu_stat = 1;
				menu_draw = 0;
			}
		}
	}
}


int autofire_fps = 2;

void autofire_fresh(void)
{
	char buf[16];
	sprintf(buf, "%2.1fHz ", 60.0/autofire_fps);
	consoletext(64*18 + 25*2, buf, 0);
	//some code on romloader.c
	__af_start = ((autofire_fps >> 1) << 8) + (autofire_fps >> 1) + (autofire_fps & 1);
}

void menu_game_input(void)
{
	do_top_menu();
	if(menu_stat == 5) {
		add_buttonp(2, &button_intput[0]);
		add_buttonp(2, &button_intput[1]);
		add_buttonp(2, &button_intput[2]);
		show_button_group(2);
		consoletext(64*18 +  15* 2, "Auto-fire:", 0);
		autofire_fresh();
		menu_stat = 6;
	}

	if(lastbutton && touchstate == 4) {
		if(lastbutton_type == 2) {
			switch(lastbutton_cnt) {
			case 0:
				draw_button(lastbutton->name, lastbutton->x, lastbutton->y, lastbutton->w, lastbutton->h, 0);
				lastbutton->stat = 0;
				lastbutton = NULL;
				joyflags ^= B_A_SWAP;
				break;
			case 1:
				if(autofire_fps > 2) {
					autofire_fps--;
					autofire_fresh();
				}
				break;
			case 2:
				if(autofire_fps < 30) {
					autofire_fps++;
					autofire_fresh();
				}
				break;
			}	
		}
	}
	menu_touchcontroller();
}

void menu_game_reset(void)
{ 
	menu_stat = 0;
	menu_draw = 0;
	menu_depth = 1;
	NES_reset();
	hideconsole();
}

void menu_input_start(void)
{
	menu_stat = 5;
	menu_func = menu_game_input;
	user_bcnt = 0;
	lastbutton = NULL;
}


char *blendnames[] = {
	"Flicker", "None   ", "","\x7F-lerp ",
};

char *rendernames[] = {
	"SP-Perframe", "SP-Pertile ", "Pure-Soft   "
};

void menu_display_start(void)
{
	consoletext(64*12 + 4, "Blend:", 0);
	consoletext(64*12 + 16, blendnames[__emuflags&3], 0x1000);
	consoletext(64*19 + 4, "Render Type:", 0);
	consoletext(64*19 + 28, rendernames[(__emuflags >> 6)&3], 0x1000);
	consoletext(64*19 + 4, "Render Type:", 0);
	consoletext(64*19 + 28, rendernames[(__emuflags >> 6)&3], 0x1000);
	consoletext(64*4 + 17*2, "Frame-skip for\rPure-Soft:", 0);
	hex8(64*5 + 27*2, soft_frameskip - 1);
	consoletext(64*11 + 23*2, "Palette\rsync:", 0);
	consoletext(64*12 + 28*2, __emuflags&PALSYNC ? "On " : "Off", 0x1000); 
}


touchstring scaleopts[]={
	{64*12+26,"\x80"}, {64*12+36,"\x81"}, {64*11+30,"\x84\x85"}, {64*14+30,"\x86\x87"},{-1,0}
};

int adjustdisplay(void) 
{
	return 0;
}

int ad_scale=0xe000, ad_ypos=-0x00060000;
void menu_display_adjust(void) {
	int i,j;
	u32 dts;
	static int dragging=0;
	
	do_top_menu();

	consoletext(64*5+0,"Touch anywhere to adjust screen.",0);
	consoletext(64*6+4,"Use arrows for fine control.",0);

	dts=do_touchstrings(scaleopts,0);
	if(touchstate==2 && dts==-1 && !(last_x>88 && last_x<168 && last_y>72 && last_y<128) && last_y>24) {	//pen down, no strings hit, outside of arrow box
		dragging=1;
	}

	if(dragging) {
		if(touchstate==4) {
			dragging=0;
			touchstate=1;	//hide touch input from tab+exit text
		} else {
			i=IPC_TOUCH_X-24;
			if(i<0) i=0;
			if(i>207) i=207;
			i*=48;
			i/=208;
			i+=192;			//i=192..239

			j=IPC_TOUCH_Y;
			j*=(239-i);
			j/=192;
			j=-j;

			i=(192*65536)/i;
			
			ad_scale=i;
			ad_ypos=j<<16;
			touchstate=3;	//hide touch input from tab+exit text
		}
	} else {
		switch(dts) {
			case 0: //left
				ad_scale+=0x100;
				break;
			case 1: //right
				ad_scale-=0x100;
				break;
			case 2: //up
				ad_ypos+=0x2000;
				break;
			case 3: //down
				ad_ypos-=0x2000;
				break;
		}
	}

	if(touchstate>1) {
		rescale(ad_scale,ad_ypos);
		REG_BG3PD = 512 - (ad_scale >> 8);
		if(ad_ypos >= 0)
			REG_BG3Y = -(ad_ypos >> 8);
		else 
			REG_BG3Y = ((-ad_ypos) >> 8);
	}
	hex16(64*12+28,ad_scale);
	hex16(64*13+28,ad_ypos>>8);
}


void menu_display_br(void)
{
	if(lastbutton_cnt > 0 && lastbutton_cnt <= 6) {
		if(lastbutton_cnt <= 3) {
			__emuflags &= ~3;
			switch(lastbutton_cnt) {
				case 1:
					__emuflags |= 3;//alpha lerp
					break;
				case 2:
					break;
				case 3:
					__emuflags |= 1;//noflicker
					break;
			}
			rescale(ad_scale,ad_ypos);
		}
		else {
			int type = lastbutton_cnt - 4;
			int i;
			__emuflags &= ~(3 << 6);
			__emuflags += type << 6;				

			switch(type) {
			case 0:	
				{
					videoSetMode(MODE_0_2D);
					videoBgDisable(3);
					for(i = 0; i < 4*8/4; i++) {
						agb_bg_map[i] = -1;
					}
				}
				break;
			case 1: //sp-perline
				{
					videoSetMode(MODE_0_2D);
					videoBgDisable(3);
					for(i = 0; i < 4*8/4; i++) {
						agb_bg_map[i] = -1;
					}
				}
				break;
			case 2: //pure-soft
				{
					videoSetMode(MODE_5_2D);
					videoBgEnable(3);
					BGCTRL[3] = (typeof(BGCTRL_SUB[3]))(BgSize_B8_256x256 | BG_MAP_BASE(0) | BG_TILE_BASE(0));	//This is weird....
					//bgInit(3, BgType_Bmp8, BgSize_B8_256x256, 0,0);
					REG_BG3PA = 256;
					REG_BG3PB = 0;
					REG_BG3PC = 0;
					REG_BG3PD = 512 - (ad_scale >> 8);
					swiWaitForVBlank();
					videoSetMode(MODE_5_2D);
					videoBgEnable(3);
					BGCTRL[3] = (typeof(BGCTRL_SUB[3]))(BgSize_B8_256x256  | BG_MAP_BASE(0) | BG_TILE_BASE(0));
					REG_BG3PA = 256;
					REG_BG3PB = 0;
					REG_BG3PC = 0;
					REG_BG3PD = 512 - (ad_scale >> 8);
				}
				break;
			}
		}
		//consoletext(64*12 + 4, "Blend Type:", 0);
		consoletext(64*12 + 16, blendnames[__emuflags&3], 0x1000);
		//consoletext(64*19 + 4, "Render Type:", 0);
		consoletext(64*19 + 28, rendernames[(__emuflags >> 6)&3], 0x1000);
	} else if(lastbutton_cnt < 9) {
		if(lastbutton_cnt & 1) {
			if(soft_frameskip > 1)
				soft_frameskip--;
		}
		else {
			if(soft_frameskip < 0xf)
				soft_frameskip++;
		}
		hex8(64*5 + 27*2, soft_frameskip - 1);
	}
	else if(lastbutton_cnt == 9) {
		__emuflags ^= PALSYNC;
		if(__emuflags & (SOFTRENDER | PALTIMING))
			__emuflags &= ~PALSYNC;
		consoletext(64*12 + 28*2, __emuflags&PALSYNC ? "On " : "Off", 0x1000); 
	}
	menu_stat = 3;
}

void menu_adjust_start(void)
{
	menu_stat = 5;
	menu_func = menu_display_adjust;
	lastbutton = NULL;
}



struct button button_nifi[] = {
	{.name = "\rAs a host", .x = 1, .y = 5, .w = 9, .h = 3},
	{.name = "\rAs a guest", .x = 16, .y = 5, .w = 10, .h = 3},
	{.name = "\rClose Nifi", .x = 1, .y = 12, .w = 10, .h = 3},
};

char *nifi_chars[] = 
{
	"Single player. IDLE.        ",
	"Waiting for 2P.             ",
	"Searching for a host(1P).   ",
	"Connected, waiting for crc. ",
	"Connected, sending crc.     ",
	"HOST:Playing. Multi-players.",
	"GUEST:Playing.              ",
};

void menu_nifi_start(void)
{
	menu_stat = 5;
	menu_func = menu_nifi_action;
	user_bcnt = 0;
	add_buttonp(2, &button_nifi[0]);
	add_buttonp(2, &button_nifi[1]);
	add_buttonp(2, &button_nifi[2]);
	show_button_group(2);
	lastbutton = NULL;
	
	consoletext(64*19+2, "Nifi Status:", 0);
	consoletext(64*20+2, nifi_chars[nifi_stat], 0);
}

void menu_nifi_action(void)
{
	do_top_menu();

	if(lastbutton && touchstate == 4) {
		if(lastbutton_type == 2) {
			switch(lastbutton_cnt) {
			case 0:
				if(!nifi_stat)
					nifi_stat = 1;
				break;
			case 1:
				if(!nifi_stat)
					nifi_stat = 2;
				break;
			case 2:
				nifi_stat = 0;
				break;
			}
			consoletext(64*20+2, nifi_chars[nifi_stat], 0);
		}
	}
}


struct menu_item menu_extra_fds_item[] = {
	{.name = "\rDisk A", .type = 1, .x = 1, .y = 6, .w = 6, .h = 3, .func = menu_extra_fds},
	{.name = "\rDisk B", .type = 1, .x = 16, .y = 6, .w = 6, .h = 3, .func = menu_extra_fds},
	{.name = "\rDisk C", .type = 1, .x = 1, .y = 15, .w = 6, .h = 3, .func = menu_extra_fds},
	{.name = "\rDisk D", .type = 1, .x = 16, .y = 15, .w = 6, .h = 3, .func = menu_extra_fds},
};
struct menu_unit menuextra_fds = {
	.top = "FDS",
	.subcnt = 4,
	.item = menu_extra_fds_item,
};

struct menu_item menu_extra_barcode_item[] = {
	{.name = "\r 0 ", .type = 1, .x = 1, .y = 14, .w = 3, .h = 3, .func = menu_extra_barcode},
	{.name = "\r 1 ", .type = 1, .x = 7, .y = 14, .w = 3, .h = 3, .func = menu_extra_barcode},
	{.name = "\r 2 ", .type = 1, .x = 13, .y = 14, .w = 3, .h = 3, .func = menu_extra_barcode},
	{.name = "\r 3 ", .type = 1, .x = 19, .y = 14, .w = 3, .h = 3, .func = menu_extra_barcode},
	{.name = "\r 4 ", .type = 1, .x = 25, .y = 14, .w = 3, .h = 3, .func = menu_extra_barcode},
	{.name = "\r 5 ", .type = 1, .x = 1, .y = 19, .w = 3, .h = 3, .func = menu_extra_barcode},
	{.name = "\r 6 ", .type = 1, .x = 7, .y = 19, .w = 3, .h = 3, .func = menu_extra_barcode},
	{.name = "\r 7 ", .type = 1, .x = 13, .y = 19, .w = 3, .h = 3, .func = menu_extra_barcode},
	{.name = "\r 8 ", .type = 1, .x = 19, .y = 19, .w = 3, .h = 3, .func = menu_extra_barcode},
	{.name = "\r 9 ", .type = 1, .x = 25, .y = 19, .w = 3, .h = 3, .func = menu_extra_barcode},
	{.name = "\rTransfer", .type = 1, .x = 1, .y = 9, .w = 8, .h = 3, .func = menu_extra_barcode},
	{.name = "\rRandom", .type = 1, .x = 13, .y = 9, .w = 6, .h = 3, .func = menu_extra_barcode},
	{.name = "\rClear", .type = 1, .x = 23, .y = 9, .w = 5, .h = 3, .func = menu_extra_barcode},
	{.name = "\rDel", .type = 1, .x = 25, .y = 4, .w = 3, .h = 3, .func = menu_extra_barcode},
};
struct menu_unit menuextra_barcode = {
	.top = "Barcode",
	.subcnt = 14,
	.item = menu_extra_barcode_item,
	.start = menu_extra_barcode_start,
};

struct button button_extra[] = {
	{.name = "\rLightGun", .x = 1, .y = 5, .w = 8, .h = 3},
	{.name = "LightGun\r&\rSwapScreen", .x = 16, .y = 5, .w = 10, .h = 3},
	{.name = "\rMicphone", .x = 1, .y = 12, .w = 8, .h = 3},
	{.name = "\rFDS Disks", .x = 16, .y = 12, .w = 9, .h = 3},
	{.name = "\rBarcode", .x = 1, .y = 19, .w = 7, .h = 3},
	{.name = "\rSave FDS", .x = 16, .y = 19, .w = 8, .h = 3},
};

void menu_extra_start(void)
{
	menu_stat = 5;
	menu_func = menu_extra_action;
	user_bcnt = 0;
	add_buttonp(2, &button_extra[0]);
	add_buttonp(2, &button_extra[1]);
	add_buttonp(2, &button_extra[2]);
	add_buttonp(2, &button_extra[3]);
	add_buttonp(2, &button_extra[4]);
	add_buttonp(2, &button_extra[5]);
	show_button_group(2);
	lastbutton = NULL;
	
	consoletext(64*10+2, "Touch to active\rthe MIC bit.", 0);
}

void menu_extra_action(void)
{
	do_top_menu();

	if(lastbutton && touchstate == 4) {
		if(lastbutton_type == 2) {
			switch(lastbutton_cnt) {
			case 0:
				__emuflags|=LIGHTGUN;
				menu_stat = 0;
				menu_draw = 0;
				__emuflags &= ~SCREENSWAP;
				hideconsole();
				break;
			case 1:
				__emuflags|=LIGHTGUN;
				menu_stat = 0;
				menu_draw = 0;
				__emuflags |= SCREENSWAP;
				lcdMainOnBottom();
				powerOn(PM_BACKLIGHT_BOTTOM);
				powerOff(PM_BACKLIGHT_TOP);
				break;
			case 3:
				last_menu = &menuextra_fds;
				menu_array[menu_depth] = last_menu;
				menu_depth++;
				menu_stat = 1;
				menu_draw = 0;
				lastbutton = NULL;
				break;
			case 4:
				last_menu = &menuextra_barcode;
				menu_array[menu_depth] = last_menu;
				menu_depth++;
				menu_stat = 1;
				menu_draw = 0;
				lastbutton = NULL;
				break;
			case 5:
				{
					FILE *f;

					if(active_interface || debuginfo[16] == 20) {
						romfileext[0]='f';
						romfileext[1]='d';
						romfileext[2]='s';
						romfileext[3]=0;
						f=fopen(romfilename,"w");
						if(f) {
							fwrite((u8*)rom_start,1,16 + (65500 * (__prgsize16k >> 2)),f);
							fflush(f);
							fclose(f);
						}
					}
				}
				break;
			}
		}
	}	

	if(lastbutton && touchstate == 3) {
		if(lastbutton_type == 2) {
			if(lastbutton_cnt == 2) {
				__emuflags |= MICBIT;
			}
		}
	}
}

char barstr[16];
char barstr_bk[16];
int barpos = 0;
void menu_extra_barcode_start(void)
{
	consoletext(64 * 4, "The length of barcode\rmust be 8 or 13.\rCode:[________]", 0);
	memset(barstr, '_', 16);
	barstr[13] = 0;
	barpos = 0;
}

void menu_extra_barcode(void)
{
	menu_stat = 3;
	if(lastbutton_cnt < 10) {
		if(barpos < 13) {
			barstr[barpos++] = lastbutton_cnt + '0';
			if(barpos == 8) {
				barstr[8] = '_';
			}
		}
	}
	else switch(lastbutton_cnt) {
		case 10:	//transfer
			if(barpos == 8 || barpos == 13) {
				memcpy(barstr_bk, barstr, 16);
				setbarcodedata(barstr_bk, barpos);
			}
			return;
			break;
		case 11:	//random
			{
				int	digit, sum, i;
				sum = 0;
				for( i = 0; i < 12; i++ ) {
					digit = rand()%10;
					barstr[i] = '0'+digit;
					sum += digit*((i&1)?3:1);
				}
				barstr[12] = '0'+((10-(sum%10))%10);
				barstr[13] = '\0';
				barpos = 13;
			}
			break;
		case 12:	//clear
			memset(barstr, '_', 16);
			barstr[13] = 0;
			barpos = 0;
			break;
		case 13:	//del
			if(barpos > 0) {
				barstr[--barpos] = '_';
			}
			break;
	}
	if(barpos < 9) {
		barstr[8] = 0;
		consoletext(64 * 6 + 28, "]", 0);
		consoletext(64 * 6 + 30, "      ", 0);
	}
	else {
		barstr[13] = 0;
		consoletext(64 * 6 + 38, "]", 0);
	}
	if(barpos == 8 || barpos == 13)
		consoletext(64 * 6 + 12, barstr, 0x1000);
	else
		consoletext(64 * 6 + 12, barstr, 0);
}

void menu_cheat_search_start(void)
{
	menu_stat = 5;
	menu_func = menu_search_action;
	user_bcnt = 0;
}

void menu_cheat_list_start(void)
{
	menu_stat = 5;
	menu_func = menu_list_action;
	user_bcnt = 0;
}

void menu_search_action(void)
{
	do_top_menu();
	addcheat();
}

void menu_list_action(void)
{
	do_top_menu();
	cheatlist();
}

void menu_cht_action(void)
{
	menu_stat = 3;
	if(lastbutton_cnt & 1)
		load_cheat();
	else
		save_cheat();
}

void menu_debug_start(void)
{
	menu_stat = 5;
	menu_func = menu_debug_action;
	user_bcnt = 0;
}

void menu_debug_action(void)
{
	do_top_menu();
	debugdump();
}

int sc = 0;
char sckeys[] = "AB  \x81\x80\x82\x83RLXY";
int sckeyvs[] = {KEY_L, KEY_R, KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_Y, KEY_X, KEY_B, KEY_A, KEY_START, KEY_SELECT};
char scbuf[] = " ";

void menu_shortcut_fresh(void)
{
	int i;
	int len = 0;
	memset((void *)(SUB_BG + 64*4),0,48);
	memset((void *)(SUB_BG + 64*5),0,48);
	memset((void *)(SUB_BG + 64*6),0,48);
	memset((void *)(SUB_BG + 64*7),0,64);
	memset((void *)(SUB_BG + 64*8),0,48);
	memset((void *)(SUB_BG + 64*9),0,48);
	memset((void *)(SUB_BG + 64*10),0,48);
	memset((void *)(SUB_BG + 64*11),0,48);
	consoletext(64 * 4, "Short-Cut:\r \rAction:\r \rkeys:\r \r \rGesture:", 0);
	consoletext(64 * 4 + 12 * 2, "   of   ", 0);
	hex8(64 * 4 + 12 * 2, sc);
	hex8(64 * 4 + 18 * 2, MAX_SC - 1);
	consoletext(64 * 5, ishortcuts[sc], 0x1000);
	consoletext(64 * 7, hshortcuts[sc], 0);
	consoletext(64 * 11 + 16, gestures_tbl[sc], 0x1000);

	if(shortcuts_tbl[sc] & (1 << 3)) {
		consoletext(64 * 9, "Start", 0x1000);
		len += 6;
	}
	if(shortcuts_tbl[sc] & (1 << 2)) {
		consoletext(64 * 9 + len * 2, "Select", 0x1000);
		len += 7;
	}
	len = (len + 31) & ~31;

	for(i = 0; i < 2; i++) {
		if(shortcuts_tbl[sc] & (1 << i)) {
			scbuf[0] = sckeys[i];
			consoletext(64 * 9 + len * 2, scbuf, 0x1000);
			len += 2;
		}
	}
	for(i = 4; i < sizeof(sckeys); i++) {
		if(shortcuts_tbl[sc] & (1 << i)) {
			scbuf[0] = sckeys[i];
			consoletext(64 * 9 + len * 2, scbuf, 0x1000);
			len += 2;
		}
	}
}

void menu_shortcut_start(void)
{
	sc = 0;
	menu_shortcut_fresh();
}

void menu_gesture_func(void)
{
	int ret;
	memset(gestures_tbl[sc], 0, 17);
	if(!(ret = get_gesture(64 * 11 + 16)))
		return;
	if(ret > 0) {
		memcpy(gestures_tbl[sc], gesture_combo, 17);
	}
	menu_stat = 3;
	consoletext(64 * 11, "Gesture:", 0);
	consoletext(64 * 11 + 16, gestures_tbl[sc], 0x1000);
}

void menu_shortcut_func(void)
{
	menu_stat = 3;
	if(lastbutton_cnt < 12)
		shortcuts_tbl[sc] ^= sckeyvs[lastbutton_cnt];
	else {
		switch(lastbutton_cnt) {
		case 12:
			shortcuts_tbl[sc] = 0;
			memset(gestures_tbl[sc], 0, 17);
			break;
		case 13:
			sc++;
			if(sc >= MAX_SC)
				sc = 0;
			break;
		case 14:
			sc--;
			if(sc < 0)
				sc = MAX_SC - 1;
			break;
		case 15:
			menu_stat = 5;
			menu_func = menu_gesture_func;
			consoletext(64 * 11, "Gesture:                ", 0x1000);
			return;
			break;
		}
	}
	menu_shortcut_fresh();
}

void menu_config_func(void)
{
	menu_stat = 3;
	switch(lastbutton_cnt) {
	case 0:	//auto
		__emuflags |= AUTOSRAM;
		break;
	case 1: //manual
		__emuflags &= ~AUTOSRAM;
		break;
	case 2: //On top
		__emuflags &=~SCREENSWAP;
		break;
	case 3: //On sub
		__emuflags |= SCREENSWAP;
		break;
	case 4: //Sound reset
		fifoSendValue32(FIFO_USER_08, FIFO_SOUND_RESET);
		break;
	}
}

void menu_about_start(void)
{
	menu_stat = 5;
	menu_func = menu_about_action;
	user_bcnt = 0;
}

void menu_about_action(void)
{
	do_top_menu();
	nesds_about();
}

void menu_extra_fds(void)
{
	menu_stat = 3;
	if(lastbutton_cnt < 4)
		fdscmdwrite(lastbutton_cnt);
}

char nesdsini[1024];

void menu_saveini(void)
{
	int pos = 0;
	int i, j, k;

	menu_stat = 3;

	if(!active_interface) return;

	inibuf[0] = 0;
	getcwd(inibuf, 512);

	//StartIn
	for(i = 0; i < strlen(inibuf); i++) {
		if(inibuf[i] == '/')
			break;
	}
	if(i >= strlen(inibuf))
		i = 0;

	ini_puts("nesDSrev2", "StartIn", inibuf + i, ininame);

	if(joyflags & B_A_SWAP)	i = 1;
	else i = 0;
	ini_putl("nesDSrev2", "BASwap", i, ininame);
	
	i = __emuflags& 3;
	ini_putl("nesDSrev2", "Blend", i, ininame);

	i = (__emuflags & PALTIMING) ? 1 : 0;
	ini_putl("nesDSrev2", "PALTiming", i, ininame);

	i = (__emuflags >> 6) & 3;
	ini_putl("nesDSrev2", "Render", i, ininame);

	i = (__emuflags & AUTOSRAM) ? 1 : 0;
	ini_putl("nesDSrev2", "AutoSRAM", i, ininame);

	i = (__emuflags & SCREENSWAP) ? 1 : 0;
	ini_putl("nesDSrev2", "ScreenSwap", i, ininame);

	ini_putl("nesDSrev2", "Screen_Scale", ad_scale, ininame);
	ini_putl("nesDSrev2", "Screen_Offset", ad_ypos, ininame);
	ini_putl("nesDSrev2", "AutoFire", autofire_fps, ininame);

	//short-cuts
	for(i = 0; i < MAX_SC; i++) {
		pos = 0;
		k = 0;
		nesdsini[0] = 0;
		for(j = 0; j < 12; j++) {
			if(shortcuts_tbl[i] & (1 << j)) {
				pos += sprintf(nesdsini + pos, "%s, ", keystrs[j]);
				k++;
			}
		}
		if(k != 0)
			ini_puts("nesDSrev2", ishortcuts[i], nesdsini, ininame);
		else
			ini_putl("nesDSrev2", ishortcuts[i], 0, ininame);
		ini_puts("nesDSrev2", igestures[i], gestures_tbl[i], ininame);
	}
}
