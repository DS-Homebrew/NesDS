#include <nds.h>
#include <stdio.h>
#include <string.h>
#include "menu.h"
#include "ds_misc.h"
#include "c_defs.h"

struct cheatlist_s
{
	unsigned int add;
	unsigned char val;
	unsigned char type;
};

struct cheatlist_s cheatlistdata[100];

int cheatcount = 0;//all codes below are for the cheat func.
char * searchtypechar[] = {"number      ", "equal     = ", "not equal !=", "increase  + ", "decrease  - ", "map       ? "};
touchstring cheattouch1[] = {
{64 * 4, "searchtype"},
{64 * 5 + 26, "\x82"}, {64 * 5 + 30, "\x82"}, 
{64 * 7 + 26, "\x83"}, {64 * 7 + 30, "\x83"},
{64 * 8, "start"},
{64 * 8 + 40, "new search"},
{-1, 0}
};

touchstring cheataddtouch[] = {
{64 * 11 - 8, "+"},
{64 * 12 - 4, "+"},
{64 * 13 - 8, "+"},
{64 * 14 - 4, "+"},
{64 * 15 - 8, "+"},
{64 * 16 - 4, "+"},
{64 * 17 - 8, "+"},
{64 * 18 - 4, "+"},
{64 * 19 - 8, "+"},
{64 * 20 - 4, "+"},
{64 * 21 - 8, "+"},
{64 * 22 - 4, "+"},
{-1, 0}
};

//load a cheat file.
void load_cheat(void)
{
	FILE *f;
	char buf[1024];
	int len;

	if(!active_interface) return;

	romfileext[0]='c';
	romfileext[1]='h';
	romfileext[2]='t';
	romfileext[3]=0;
	f=fopen(romfilename,"r");
	if(!f) return;
	len=fread(buf,1,1024,f);
	fclose(f);
	memcpy(&cheatcount, buf, 4);
	memcpy(cheatlistdata, buf + 4, sizeof(cheatlistdata));
	if(len != 1024) {
		cheatcount = 0;
	}
}

//save to a cheat file.
void save_cheat(void)
{
	FILE *f;
	char buf[1024];

	if(!active_interface) return;

	romfileext[0]='c';
	romfileext[1]='h';
	romfileext[2]='t';
	romfileext[3]=0;
	f=fopen(romfilename,"w");
	if(!f) return;
	memcpy(buf, &cheatcount, 4);
	memcpy(buf + 4, cheatlistdata, sizeof(cheatlistdata));
	fwrite(buf,1,1024,f);
	fflush(f);
	fclose(f);
}

// add a cheat list to the Chtlist menu....
void addcheatlist(int add)
{
	if(cheatcount >= 14)
		return;
	cheatlistdata[cheatcount].add = add;
	cheatlistdata[cheatcount].val = *(char *)(NES_RAM + add);
	cheatlistdata[cheatcount].type = 2;
	cheatcount++;
}

unsigned char lastcheatdata[0x800];
unsigned char cheatdata[0x800];
char lastcheatstatus[0x800];
//do cheat search or something else
int addcheat()
{
	static int searchnum = 0;
	static int searchtype = 0;
	static int count = 0;
	static char newsearch = 1;
	char *p;
	int i;
	p = (char *)NES_RAM;//NDS_RAM
	consoletext(64 * 4, "searchtype: ", 0);
	consoletext(64 * 4 + 24, searchtypechar[searchtype], 0);
	consoletext(64 * 6, "searchnum: 0x", 0);
	hex(64 * 6 + 26, searchnum >> 4, 0);
	hex(64 * 6 + 30, searchnum, 0);
	i = do_touchstrings(cheattouch1, 0);
	if(touchstate==4) {
		switch(i)  {
			case 0:
				searchtype++;
				if(searchtype > 5)
					searchtype = 0;
				break;
			case 1:
				searchnum += 0x10;
				break;
			case 2:
				searchnum += 0x01;
				break;
			case 3:
				searchnum -= 0x10;
				break;
			case 4:
				searchnum -= 0x01;
				break;
			case 6:
				newsearch = 1;
			case 5:
				{
					count = 0;
					for(i = 10; i < 22; i++)  {
						consoletext(64 * i, "                                ", 0);
					}
					for(i = 0; i < 0x800; i++)  {
						if(lastcheatstatus[i] || searchtype == 5)  {
							lastcheatstatus[i] = 0;
							switch(searchtype)  {
								case 0:
									if(*p == searchnum)
										lastcheatstatus[i] = 1;
									break;
								case 1:
									if(*p == lastcheatdata[i])
										lastcheatstatus[i] = 1;
									break;
								case 2:
									if(*p != lastcheatdata[i])
										lastcheatstatus[i] = 1;
									break;
								case 3:
									if(*p > lastcheatdata[i])
										lastcheatstatus[i] = 1;
									break;
								case 4:
									if(*p < lastcheatdata[i])
										lastcheatstatus[i] = 1;
									break;
								case 5:
									lastcheatstatus[i] = 1;
									break;
							}
						}
						if(newsearch == 1)
							lastcheatstatus[i] = 1;
						if(lastcheatstatus[i]) {
							count++;
							lastcheatdata[i] = cheatdata[i];
							cheatdata[i] = *p;
						}
						p++;
					}
					newsearch = 0;
				}
				break;
			default:
				break;
		}
		searchnum = searchnum&0xff;
	}
	consoletext(64 * 9, "found:0x", 0);
	hex(64 * 9 + 16, count, 3);
	if(count > 0)  {
		count = 0;
		for(i = 0; i < 0x800; i++)  {
			if(lastcheatstatus[i])  {
				if (count < 11)  {
					consoletext(64 * 10 + 64 * count, "add:0x    old:0x   new:0x  ", 0);
					hex(64 * 10 + 64 * count + 12, i, 2);
					hex(64 * 10 + 64 * count + 32, lastcheatdata[i], 1);
					hex(64 * 10 + 64 * count + 50, cheatdata[i], 1);
				}
				count++;
			}
		}
	}
	if(count > 0)  {
		int showcount;
		showcount = count > 10? 11:count;
		cheataddtouch[showcount].offset = -1;
		i = do_touchstrings(cheataddtouch, 0);
		cheataddtouch[showcount].offset = 64 * (11 + showcount) - ((showcount&1)?4:8);
		if(touchstate==4) {
			if(i >= 0)  {
				int j;
				count = 0;
				for(j = 0; j < 0x800; j++)  {
					if(lastcheatstatus[j] == 1) count++;
					if(count == i + 1)  {
						break;
					}
				}
				addcheatlist(j);
			}
		}
	}
	return 0;
}

touchstring cheatlisttouch[] = {
{0, "E"},
{-1,0}
};

// to maintain cheat list
int cheatlist()
{
	char *type[] = {"fix", "once", "once"};
	int i;
	static char state;//1 edit 0 null
	static unsigned char editnum;
	static unsigned int preadd;
	static unsigned char preval, pretype;

	if(menu_stat == 5) {
		for(i = 4; i <= 24; i++)  {
			consoletext(64 * i, "                                ", 0);
		}
		menu_stat = 6;
	}
	for(i = 4; i < cheatcount + 4; i++)  {
		int j;
		consoletext(64 * i, "add:0x    val:0x   type:        ", 0);
		hex(64 * i + 12, cheatlistdata[i - 4].add, 2);
		hex(64 * i + 12 + 20, cheatlistdata[i - 4].val, 1);
		consoletext(64 * i + 30 + 8 + 10, type[cheatlistdata[i - 4].type], 0);
		if(i&1)
			cheatlisttouch[0].offset = 64 * i + 60;
		else
			cheatlisttouch[0].offset = 64 * i + 56;
		j = do_touchstrings(cheatlisttouch, 0);
		if(touchstate==4 && j == 0)  {
			state = 1;
			editnum = i - 4;
			preadd = cheatlistdata[editnum].add;
			preval = cheatlistdata[editnum].val;
			pretype = cheatlistdata[editnum].type;
		}		
	}

	if(state == 1)  {
		touchstring mytouch[] = {
			{64 * 19 + 4,"\x82"},
			{64 * 19 + 8,"\x82"},
			{64 * 19 + 12,"\x82"},
			{64 * 19 + 20,"\x82"},
			{64 * 19 + 24,"\x82"},
			{64 * 21 + 4,"\x83"},
			{64 * 21 + 8,"\x83"},
			{64 * 21 + 12,"\x83"},
			{64 * 21 + 20,"\x83"},
			{64 * 21 + 24,"\x83"},
			{64 * 20 + 32, "type"},
			{64 * 20 + 52, "ok"},
			{64 * 20 + 58, "del"},
			{-1, 0}
		};
		consoletext(64 * 20, "0x      0x          :           ", 0);
		hex(64 * 20 + 4, preadd >> 8, 0);
		hex(64 * 20 + 8, preadd >> 4, 0);
		hex(64 * 20 + 12, preadd, 0);
		hex(64 * 20 + 20, preval >> 4, 0);
		hex(64 * 20 + 24, preval, 0);
		consoletext(64 * 20 + 42, type[pretype], 0);
		i = do_touchstrings(mytouch, 0);
		if(touchstate==4)  {
			if(i >=0 && i <= 12)
				menu_stat = 5;
			switch(i)  {
				case 0:
					preadd += 0x100;
					break;
				case 1:
					preadd += 0x010;
					break;
				case 2:
					preadd += 0x001;
					break;
				case 3:
					preval += 0x10;
					break;
				case 4:
					preval += 0x01;
					break;
				case 5:
					preadd -= 0x100;
					break;
				case 6:
					preadd -= 0x010;
					break;
				case 7:
					preadd -= 0x001;
					break;
				case 8:
					preval -= 0x10;
					break;
				case 9:
					preval -= 0x01;
					break;
				case 10:
					pretype = pretype?0:1;
					break;
				case 11:
					cheatlistdata[editnum].add = preadd;
					cheatlistdata[editnum].val = preval;
					cheatlistdata[editnum].type = pretype? 1:0;
					state = 0;
					break;
				case 12:	
					{
						int k;
						for(k = i - 4; k < cheatcount; k++)  {
							cheatlistdata[k].add = cheatlistdata[k + 1].add;
							cheatlistdata[k].val = cheatlistdata[k + 1].val;
							cheatlistdata[k].type = cheatlistdata[k + 1].type;
						}
						cheatcount--;
						state = 0;
					}
					break;
			}
			preval &= 0xFF;
			preadd &= 0x7FF;
		}
	}
	else  {
		touchstring mytouch[] = {
			{64 * 20 + 40, "add new one"},
			{-1, 0},
		};
		i = do_touchstrings(mytouch, 0);
		if(touchstate==4) {
			switch(i) {
				case 0:	//add new one
					if(cheatcount < 14) {
						cheatlistdata[cheatcount].add = 0;
						cheatlistdata[cheatcount].val = 0;
						cheatlistdata[cheatcount].type = 2;
						cheatcount ++;
					}
					menu_stat = 5;
					break;
			}
		}
	}
	return 0;
}

// do the cheat in the main loop

int do_cheat()
{
	int i;
	if(cheatcount)  {
		for(i = 0; i < cheatcount; i++)  {
			if(cheatlistdata[i].type == 0)  {
				*(char *)(NES_RAM + cheatlistdata[i].add) = cheatlistdata[i].val;
			}
			else if(cheatlistdata[i].type == 1)  {
				*(char *)(NES_RAM + cheatlistdata[i].add) = cheatlistdata[i].val;
				cheatlistdata[i].type = 2;
			}
		}
	}
	return 0;
}
