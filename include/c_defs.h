//FIFO_USER_06	for ipc_region
//FIFO_USER_07	for audio data
//FIFO_USER_08  for APU control

//#define DTCM 0x0b000000

#define NES_RAM nes_region
#define NES_SRAM NES_RAM + 0x800
//nes_region
#define MAX_IPS_SIZE 0x80000		//actually, the ips file won't be larger than 512kB.
#define ROM_MAX_SIZE 0x318000
#define MAXFILES 1024

#define VRAM_ABCD (*(vu32*)0x4000240)
#define VRAM_EFG (*(vu32*)0x4000244)
#define VRAM_HI (*(vu16*)0x4000248)

#undef IPC		//IPC_* also in equates.h, keep both updated
#define IPC ((u8 *)ipc_region)
#define IPC_TOUCH_X	(*(vu32*)(IPC+0))
#define IPC_TOUCH_Y	(*(vu32*)(IPC+4))
#define IPC_KEYS	(*(vu32*)(IPC+8))
#define IPC_ALIVE	(*(vu32*)(IPC+12))			//unused anymore
#define IPC_MEMTBL  ((char **)(IPC+16))
#define IPC_REG4015 (*(char *)(IPC+32))			//arm7 should not write this value but to use fifo. channel 5
#define IPC_APUIRQ  (*(char *)(IPC+33))			//not supported.
#define IPC_RAWPCMEN (*(char *)(IPC+34))			//not supported.
#define IPC_APUW (*(volatile int *)(IPC+40))		//apu write start
#define IPC_APUR (*(volatile int *)(IPC+44))		//apu write start
#define IPC_MAPPER (*(volatile int *)(IPC+48))		//nes rom mapper
#define IPC_PCMDATA		(unsigned char *)(IPC+128)	//used for raw pcm.
#define IPC_APUWRITE ((unsigned int *)(IPC+512))		//apu write start
#define IPC_AUDIODATA ((unsigned int *)(IPC+4096 + 512))	//audio data...

//not implemented yet.

#undef KEY_TOUCH
#define KEY_TOUCH 0x1000
#define KEY_CLOSED 0x2000

#define FIFO_WRITEPM 1
#define FIFO_APU_PAUSE 2
#define FIFO_UNPAUSE 3
#define FIFO_SETVOLUME 4
#define FIFO_APU_RESET 5
#define FIFO_HIBERNATE 6
#define FIFO_SOUND_RESET 7

#ifdef ARM9

typedef struct {	//rom info from builder
	char name[32];
	u32 filesize;
	u32 flags;
	u32 spritefollow;
	u32 reserved;
} romheader;	

#define SAVESTATESIZE (0x2800+0x3000+96+64+16+96+16+44+64)


//nesmain.c
extern int soft_frameskip;
extern int global_playcount;
extern int subscreen_stat;
void showversion();
void play(void);
void recorder_reset(void);

//console.c
#define SUB_CHR 0x6204000
#define SUB_BG 0x6200000
void consoleinit(void);
#define hex8(a,b) hex(a,b,1)
#define hex16(a,b) hex(a,b,3)
#define hex24(a,b) hex(a,b,5)
#define hex32(a,b) hex(a,b,7)
void hex(int offset,int d,int n);
void consoletext(int offset,char *s,int color);
void menutext(int line,char *s,int selected);
void clearconsole(void);
void hideconsole(void);
void showconsole(void);

//subscreen.c
int debugdump(void);

#define VBLS 6
#define FPS 7
extern u32 debuginfo[];
int debugdump(void);

//romloader.c
int romsize;
int bootext();
extern int active_interface;
extern char romfilename[256];
extern char *romfileext;
void do_rommenu(void);
extern int freemem_start;
//#define freemem_end 0x23e0000				//this cannot be used based on libnds
extern int freemem_end;

extern char inibuf[768];
extern char ininame[768];

//minIni.c
long ini_getl(const char *Section, const char *Key, long DefValue, const char *Filename);
int ini_puts(const char *Section, const char *Key, const char *Value, const char *Filename);
int ini_putl(const char *Section, const char *Key, long Value, const char *Filename);
int ini_gets(const char *Section, const char *Key, const char *DefValue, char *Buffer, int BufferSize, const char *Filename);

//romloader_frontend.c
bool readFrontend(char *target);


//misc.c
#define MAX_SC 19

extern char *ishortcuts[];
extern char *igestures[];
extern char *hshortcuts[];
extern int shortcuts_tbl[];
extern char *keystrs[];
extern char gestures_tbl[][32];
extern int do_gesture_type;
void do_quickf(int func);

extern int slots_num;
extern int screen_swap;
typedef struct {
	int offset;
	char *str;
} touchstring;
void do_shortcuts();
extern int touchstate, last_x, last_y;
void touch_update(void);
int do_touchstrings(touchstring*,int pushstate);
void load_sram(void);
void save_sram(void);
void write_savestate(int num);
void read_savestate(int num);
void ARM9sleep(void);
void reg4015interrupt(u32 msg, void *none);
void fdscmdwrite(u8 diskno);
void Sound_reset();
//*.s

//emuflags:
#define NOFLICKER 1
#define ALPHALERP 2
//joyflags
#define B_A_SWAP	0x80000
#define L_R_DISABLE	0x100000
//cartflags
#undef SRAM
#define SRAM 0x02

extern u32 __emuflags;		//cart.s
extern u8 __cartflags;

extern u32 joyflags;		//io.s
extern u32 joystate;
extern u32 romstart;

extern u8 mapperstate[96];	//6502.s
extern u32 __scanline;
extern u8 __barcode;
extern u8 __barcode_out;
extern u32 __af_st;
extern u32 __af_start;
extern u32 __prgsize16k;
extern u32 __nsfplay;
extern u32 __nsfinit;
extern u32 __nsfsongno;
extern u32 __nsfsongmode;

extern struct nsfheader
{
	char	ID[5];
	char	Version;
	char	TotalSong;
	char	StartSong;
	unsigned short	LoadAddress;
	unsigned short	InitAddress;
	unsigned short	PlayAddress;
	char	SongName[32];
	char	ArtistName[32];
	char	CopyrightName[32];
	unsigned short	SpeedNTSC;
	char	BankSwitch[8];
	unsigned short	SpeedPAL;
	char	NTSC_PALbits;
	char	ExtraChipSelect;
	char	Expansion[4];		// must be 0
} nsfheader;

void EMU_VBlank(void);
void EMU_Run(void);
void NSF_Run(void);
void initcart(char *rom);//,int flags);
void PPU_init(void);
void rescale_nr(u32 scale, u32 start);
void paletteinit(void);		//ppu.s
void NES_reset(void);		//cart.s
int savestate(u32);
int loadstate(u32);
void rescale(int a, int b);

//render.s
extern u32 __rendercount;	//6502.s
extern void render_all();
extern void render_sub();
extern void ntsc_pal_reset();


//multi.c
extern void initNiFi();
extern void do_multi();
extern int nifi_cmd;
extern int nifi_stat;
extern int nifi_menu();

//cheat.c
extern int do_cheat();
extern int cheatlist();
extern int addcheat();
extern void load_cheat(void);
extern void save_cheat(void);

//ips.c
void load_ips(const char *name);
void do_ips(int romsize);
extern int ips_stat;

//gesture.c
void do_gesture(void);
int get_gesture(int out);
extern int gesture;
extern char gesture_combo[32];
extern int gesture_pos;

//about.c
extern int nesds_about();

//barcode.c
extern void setbarcodedata( char *code, int len );

//memory.s
extern u8 rom_start[];
extern u8 rom_files[];
extern u32 ipc_region[];
extern u8 nes_region[];
extern u8 ct_buffer[];

//menu.h
void do_menu();

//menu_func.c
extern int ad_scale, ad_ypos;
extern int autofire_fps;

//subscreen.c
extern u32 debuginfo[];

//ppu.s
extern u32 gfx_scale;

//others...
extern u32 all_pix_start;
extern u32 all_pix_end;

//rompatch.c
extern void crcinit();
extern void romcorrect(char *s);

//zip
extern int load_gz(const char *fname);
int do_decompression(const char *inname, const char *outname);

#define MP_KEY_MSK		0x0CFF		
#define MP_HOST			(1 << 31)		
#define MP_CONN			(1 << 30)		
#define MP_RESET		(1 << 29)
#define MP_NFEN			(1 << 28)

#define MP_TIME_MSK		0xFFFF		
#define MP_TIME			16	

#define P1_ENABLE 0x10000
#define P2_ENABLE 0x20000
#define B_A_SWAP 0x80000
#define L_R_DISABLE 0x100000
#define AUTOFIRE 0x1000000
#define MIRROR 0x01 //horizontal mirroring
#define SRAM 0x02 //save SRAM
#define TRAINER 0x04 //trainer present
#define SCREEN4 0x08 //4way screen layout
#define VS 0x10 //VS unisystem
#define NOFLICKER 1	//flags&3:  0=flicker 1=noflicker 2=alphalerp
#define ALPHALERP 2
#define PALTIMING 4	//0=NTSC 1=PAL
#define FOLLOWMEM 32  //0=follow sprite, 1=follow mem
#define SPLINE 64
#define SOFTRENDER 128	//pure software rendering
#define ALLPIXEL 256 // use both screens to show the pixels
#define NEEDSRAM 512	//will autoly save sram 3 second after sram write.
#define AUTOSRAM 1024	//enable auto saving sram.
#define SCREENSWAP 2048
#define LIGHTGUN 4096	//lighting gun
#define MICBIT 8192	//Mic bit
#define PALSYNC	16384 //for palette sync
#define STRONGSYNC 32768 //for scanline sync
#define SYNC_NEED 0x18000 //need for palette sync, updated when there is writings on pal. OR STRONGSYNC is set.
#define PALSYNC_BIT	0x10000 //for pal sync. as a sign
#define FASTFORWARD 0x20000 //for fast forward
#define REWIND 0x40000 // for backward
#define ALLPIXELON 0x80000 //on or off state of all_pix_show
#define NSFFILE 0x100000 //on or off state of all_pix_show
#else
extern int ipc_region;
#endif
