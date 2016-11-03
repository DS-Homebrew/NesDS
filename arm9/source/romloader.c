#include <nds.h>
#include <stdio.h>
#include <string.h>
#include <dirent.h>
#include <stdlib.h>
#include <unistd.h>
#include "ds_misc.h"
#include "c_defs.h"
#include "minIni.h"
#include "menu.h"
//#include "extlink_filestruct.h"

extern int subscreen_stat;
extern int shortcuts_tbl[16];

char tmpname[] = "dszip.tmp";

int romsize;	//actual rom size
int freemem_start;	//points to unused mem (end of loaded rom)
int freemem_end;
u32 oldinput;

char romfilename[256];	//name of current rom.  null when there's no file (rom was embedded)
char *romfileext;	//points to file extension

//extern u8 autostate;			//from ui.c
int active_interface = 0;

void rommenu(int roms);
void drawmenu(int sel,int roms);
int getinput(void);

int init_rommenu(void);
void listrom(int line,int rom,int highlight); //print rom title
int loadrom(int rom);	//return -1 on success, or rom count (from directory change)
void stringsort(char**);

void adjust_fds(char *name, char * rom)
{
	if(strstr(name, ".FDS") || strstr(name, ".fds")) {
		rom[0] = 'F';
		rom[1] = 'D';
		rom[2] = 'S';
	}
}

int is_nsf_file(char *name, char *rom)
{
	//actually the first four chars should be "NESM"
	if(strstr(name, ".NSF") || strstr(name, ".nsf")) {
		memcpy(&nsfheader, rom, sizeof(nsfheader));
		__emuflags |= NSFFILE;
		__nsfsongno = 0;
		__nsfplay = 0;
		__nsfinit = 0;
		IPC_MAPPER = 256;
		return 1;
	}
	__emuflags &= ~NSFFILE;
	return 0;
}

/*****************************
* name:			do_rommenu
* function:		show a menu to select a nes rom file.
* argument:		none
* description:		called when starting.
******************************/
int global_roms = 0;

void do_rommenu() {
	int roms = global_roms;

	ips_stat = 0;		//disable ips first.

	fifoSendValue32(FIFO_USER_08, FIFO_APU_PAUSE);			//disable sound when selecting a rom.

	if(!global_roms) {
		roms=init_rommenu();
		global_roms = roms;
	}

	if(!roms) {
		if(!active_interface) {			//another driver is present, but init failed
			consoletext(64*3,"Device failed.",0);
		} else						//no DLDI error, no files
			consoletext(64*3,"No roms found.",0);
		
		while(1) swiWaitForVBlank();
	}
	showconsole();
	clearconsole();
	showversion();
	rommenu(global_roms);
	menu_stat = 0;
	menu_draw = 0;
	hideconsole();
	clearconsole();
}

/*****************************
* name:			rommenu
* function:		show a rom menu.
* argument:		roms: the count of valid roms.
* description:		called by do_rommenu.
******************************/
void rommenu(int roms) {
	static int selectedrom=0;
	int key;
	int sel=selectedrom;
	int loaded=0;

	save_sram();

	oldinput=IPC_KEYS;

	if(roms==1)
		key=KEY_START;
	else
		key=0x80000000;
	do {
		swiWaitForVBlank();
		switch(key) {
			case KEY_START:
			case KEY_B:
			case KEY_A:
			case KEY_Y:
				loaded=loadrom(sel);
				if(loaded > 0) {	//didn't load (it was a directory) loaded == 0 means that ips file is loaded.
					sel=0;
					roms=loaded;
					global_roms = roms;
				}
				break;
			case KEY_RIGHT:
				sel+=10;
				if(sel>roms-1) sel=roms-1;
				break;
			case KEY_LEFT:
				sel-=10;
				if(sel<0) sel=0;
				break;
			case KEY_UP:
				sel=sel+roms-1;
				break;
			case KEY_DOWN:
				sel++;
				break;
		}
		sel%=roms;
		if(key && loaded>=0)
			drawmenu(sel,roms);
		key=getinput();
	} while(loaded>=0);

	selectedrom=sel;

	load_sram();

	//if(autostate) loadstate(..);
}

#define ROWS 21
#define OFFSET 3
/*****************************
* name:			drawmenu
* function:		show a rom menu.
* argument:		sel: the select number
			roms: count of roms
* description:		called by rommenu.
******************************/
void drawmenu(int sel,int roms) {
	int i,j,topline,rom;
	
	clearconsole();
	if(roms>ROWS) {
		topline=8*(roms-ROWS)*sel/(roms-1);
		rom=topline/8;
		j=(rom<roms-ROWS)?ROWS+1:ROWS;
	} else {
		topline=0;
		rom=0;
		j=roms;
	}
	
	for(i=0;i<j;i++) {
		listrom(i+OFFSET,rom,sel==rom);
		rom++;
	}

//	if(roms>ROWS)
		REG_BG0VOFS_SUB=topline%8;
//	else
//		SUB_BG0_Y0=-(ROWS*4)+roms*4;
}

/*****************************
* name:			getinput
* function:		get a key input for rom selection.
* argument:		none
* description:		called by rommenu.
******************************/
int getinput() {
	static int lastdpad,repeatcount=0;
	int dpad;
	int keyhit;
	scanKeys();
	IPC_KEYS = keysCurrent();
	keyhit=(oldinput^IPC_KEYS)&IPC_KEYS;
	oldinput=IPC_KEYS;
	dpad=IPC_KEYS&(KEY_UP+KEY_DOWN+KEY_LEFT+KEY_RIGHT);
	if(lastdpad==dpad) {
		repeatcount++;
		if(repeatcount<25 || repeatcount&3)	//delay/repeat
			dpad=0;
	} else {
		repeatcount=0;
		lastdpad=dpad;
	}
	return dpad|(keyhit&(KEY_Y+KEY_X+KEY_A+KEY_B+KEY_START));
}

/*****************************
* name:			listrom
* function:		show a rom file name on the sub-screen.
* argument:		line: row number on the screnn.
			rom: rom number of the roms list.
			highlight: if the rom is selected(highlighted).
* description:		called by rommenu.
******************************/
void listrom(int line,int rom,int highlight) {
	char *s;
	char **files=(char**)rom_files; 
	s=files[rom];
	if(*s==1) {	//dir
		menutext(line,s+1,highlight?2:0);
	} else		//file
		menutext(line,s+1,highlight);
}

/*****************************
* name:			loadrom
* function:		load a rom to memory, for NES emulation.
* argument:		rom: rom number of the roms list.
* description:		called by rommenu.
******************************/
int loadrom(int rom) {
	int i;
	char **files=(char**)rom_files; 
	FILE *f;

	if(*files[rom]==1) {	//directory
		chdir(files[rom]+1);
		return init_rommenu();
	} else {	//file
		if(strstr(files[rom]+1, ".ips") || strstr(files[rom]+1, ".IPS")) {	// a ips file is loaded.
			load_ips(files[rom]+1);
			return 0;
		}
		else {
			char *roms;
			memcpy(romfilename,files[rom]+1,256);

			if(strstr(files[rom]+1, ".GZ") || strstr(files[rom]+1, ".gz") ||
				strstr(files[rom]+1, ".ZIP") || strstr(files[rom]+1, ".zip")
			) {	// a gz file is loaded.
				if(load_gz(files[rom]+1)) {
					return 1;	//fail to unzip.
				}
				f=fopen(tmpname,"r");
			}
			else {
				f=fopen(romfilename,"r");
			}

			romfileext=strrchr(romfilename,'.')+1;
			roms = (char *)rom_start;
			//f=fopen(romfilename,"r");
			i=fread(roms,1,ROM_MAX_SIZE,f);	//read the whole thing (filesize=some huge number, don't care)
			do_ips(i);

			fclose(f);
			if(strstr(files[rom]+1, ".GZ") || strstr(files[rom]+1, ".gz") ||
				strstr(files[rom]+1, ".ZIP") || strstr(files[rom]+1, ".zip")
				) {    // a gz file is loaded.
				unlink(tmpname);
			}
			romsize=i;
            if(i < 0x100000)
                i = 0x100000;            //leave some room for FDS files. Also the NSF file need some extra memory
            freemem_start=((u32)roms+i+3)&~3;
            freemem_end=(u32)roms+ROM_MAX_SIZE;

			if(!is_nsf_file(romfilename, roms)) {
				adjust_fds(romfilename, roms);
				romcorrect(roms);
			}
			initcart(roms);
			IPC_MAPPER = debuginfo[16];
			return -1;	//(-1 on success)
		}
	}
}

/*****************************
* name:			init_rommenu
* function:		count the nes roms&dirs in current dir...
* argument:		none
* description:		called by do_rommenu.
******************************/
//return number of file entries (roms+dirs)
int init_rommenu() {
	char **files;
	char *nextfile;
	int idx=0;
	DIR *dir = NULL;
	struct dirent *cnt = NULL;
	struct stat statbuf;

	if(!active_interface)		//DLDI trouble
		return 0;

	files = (char**)rom_files;
	nextfile=(char*)&files[MAXFILES];
	dir=opendir(".");			//chdir to root
	cnt=readdir(dir);
	stat(cnt->d_name,&statbuf);

	while(cnt != NULL && (idx<MAXFILES - 1) && dir != NULL) {
		if(((strstr(cnt->d_name, ".NES") || strstr(cnt->d_name, ".nes")) 
			|| (strstr(cnt->d_name, ".FDS") || strstr(cnt->d_name, ".fds"))
			|| (strstr(cnt->d_name, ".IPS") || strstr(cnt->d_name, ".ips"))
			|| (strstr(cnt->d_name, ".GZ") || strstr(cnt->d_name, ".gz"))
			|| (strstr(cnt->d_name, ".ZIP") || strstr(cnt->d_name, ".zip"))
			|| (strstr(cnt->d_name, ".nsf") || strstr(cnt->d_name, ".nsf"))
			|| (S_ISDIR(statbuf.st_mode)) 
			|| strcmp("..", cnt->d_name) == 0) && strcmp(".", cnt->d_name) != 0) {
			if(S_ISDIR(statbuf.st_mode) || strcmp("..", cnt->d_name) == 0)
				*nextfile = 1;
			else 
				*nextfile = 2;
			strcpy(nextfile + 1, cnt->d_name);
			files[idx]=nextfile;
			nextfile+=strlen(nextfile)+1;
			idx++;
		}
		cnt=readdir(dir);
		stat(cnt->d_name,&statbuf);
	}
	files[idx]=0;
	stringsort(files);
	if(dir)
		closedir(dir);
	return idx;
}


/*****************************
* name:			less
* function:		return (s1 < s2)
* argument:		s1, s2
* description:		cmpare to strings.for sorting.
******************************/
//case insensitive string compare
inline int less(char *s1,char *s2) {
	int c1,c2;
	do {
		c1=*s1++;
		c2=*s2++;
		if(c1>='a') c1=c1-'a'+'A';
		if(c2>='a') c2=c2-'a'+'A';
	} while(c1==c2);
	return c1<c2;
}

/*****************************
* name:			stringsort
* function:		sort the strings.
* argument:		p1: pointer of string list.
* description:		none
******************************/
//lazy man's string sorter
void stringsort(char **p1) {
	char **p2;
	char *s1,*s2;
	do {	//next s1
		s1=*p1;
		if(s1) {
			p2=p1;
			do {	//next s2
				p2++;
				s2=*p2;
				if(s2 && less(s2,s1)) {
					*p1=s2;
					*p2=s1;
					s1=s2;
				}
			} while(s2);
		}
		p1++;
	} while(s1);
}

extern int argc;
extern char **argv;
char inibuf[768];
char ininame[768];

char *findpath(int argc, char **argv, const char *name){
	int i=0;
	for(;i<argc;i++){
		strcpy(ininame,argv[i]);
		if(ininame[strlen(ininame)-1]!='/')strcat(ininame,"/");
		strcat(ininame,name);
		if(!access(ininame,0))return ininame;
	}
	ininame[0]=0;
	return NULL;
}

char none[] = " ";

int keystr2int(char *buf) 
{
	int i;
	int ret = 0;
	if(buf[0] == 0) return 0;
	for(i = 0; i < 12; i++) {
		if(strstr(buf, keystrs[i]) != NULL) {
			ret |= (1 << i);
		}
	}
	return ret;
}

int bootext() {
	//interrupt 0: set my dir (inibuf)
	int i;
	strcpy(inibuf,"/");
	if(argc>0){
		strcpy(inibuf,argv[0]);
		i=strlen(inibuf)+1;
		for(;i>0;i--)if(inibuf[i-1]=='/'){inibuf[i]=0;break;}
	}

	memset(shortcuts_tbl, 0, sizeof(shortcuts_tbl));
	if(findpath(7,(char*[]){"/","/_dstwoplug/","/ismartplug/","/moonshl2/extlink/","/_iMenu/_ini/","/_plugin_/",inibuf},"nesDS.ini")){
		//interrupt 1: read config
		int iniret;
		if((iniret=ini_getl("nesDSrev2","BASwap",0,ininame)) != 0) joyflags|=B_A_SWAP;

		if((iniret=ini_getl("nesDSrev2","LRDisable",0,ininame)) != 0) joyflags|=L_R_DISABLE;
		if((iniret=ini_getl("nesDSrev2","Blend",0,ininame)) != 0) __emuflags|=iniret&3;
		if((iniret=ini_getl("nesDSrev2","PALTiming",0,ininame)) != 0) __emuflags|=PALTIMING;
		if((iniret=ini_getl("nesDSrev2","FollowMem",0,ininame)) != 0) __emuflags|=FOLLOWMEM;
		if((iniret=ini_getl("nesDSrev2","ScreenSwap",0,ininame)) != 0) __emuflags|=SCREENSWAP;
		if((iniret=ini_getl("nesDSrev2","Render",0,ininame)) != 0)  {
			if(iniret == 1)	__emuflags|=SPLINE;
			else __emuflags|=SOFTRENDER;
		}
		if((iniret=ini_getl("nesDSrev2","AutoSRAM",0,ininame)) != 0) __emuflags|=AUTOSRAM;
		if((iniret=ini_getl("nesDSrev2","Screen_Scale",0,ininame)) != 0) ad_scale=iniret;
		if((iniret=ini_getl("nesDSrev2","Screen_Offset",0,ininame)) != 0) ad_ypos=iniret;
		if((iniret=ini_getl("nesDSrev2","AutoFire",2,ininame)) != 0) autofire_fps=iniret;
		__af_start = ((autofire_fps >> 1) << 8) + (autofire_fps >> 1) + (autofire_fps & 1);

		rescale(ad_scale, ad_ypos);

		for(i = 0 ; i < MAX_SC; i++) {
			if((iniret=ini_getl("nesDSrev2",ishortcuts[i],0,ininame)) != 0) shortcuts_tbl[i]=iniret;
			else {
				ini_gets("nesDSrev2", ishortcuts[i], none, inibuf, 512, ininame);
				shortcuts_tbl[i] = keystr2int(inibuf);
			}

			ini_gets("nesDSrev2", igestures[i], none, gestures_tbl[i], 24, ininame);
		}

		ini_gets("nesDSrev2","StartIn","/",inibuf,768,ininame);
	}
	/*else{
		strcpy(inibuf,"/");
	}*/

	if(!*inibuf||inibuf[strlen(inibuf)-1]!='/')strcat(inibuf,"/");
	chdir(inibuf); //might be overwritten in readFrontend()

	//interrupt 2: allocate buffer
	char *roms=(char *)rom_start;

	//interrupt 3: read frontend
	if(!readFrontend(romfilename)) return 0;
	romfileext=strrchr(romfilename,'.')+1;
	FILE *f=fopen(romfilename,"rb");
	if(!f)return 0;
	i=fread(roms,1,ROM_MAX_SIZE,f);	//read the whole thing (filesize=some huge number, don't care)
	romsize=i;
	if(i < 0x10000)
		i = 0x10000;			//leave some space for FDS roms. Also the NSF
	freemem_start=((u32)roms+i+3)&~3;
	freemem_end=(u32)roms+ROM_MAX_SIZE;
	fclose(f);
	if(!is_nsf_file(romfilename, roms)) {
		adjust_fds(romfilename, roms);
		romcorrect(roms);
	}
	initcart(roms);
	IPC_MAPPER = debuginfo[16];
	return 1;
}

int load_gz(const char *fname)
{
#if 1
	int ret;
	ret = do_decompression(fname, tmpname);
	return ret;
#endif
	return 0;
}
