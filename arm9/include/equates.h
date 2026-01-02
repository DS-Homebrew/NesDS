@		GBLL DEBUG
@	VERSION_IN_ROM = 0  @out of pocketnes ??
	#include "macro.h"
	#include "RP2A03.i"
	#include "RP2C02.i"
DEBUG		= 1
DEBUGSTEP	= 0
@----------------------------------------------------------------------------

wram = NES_DRAM	//64k ram is reserved here.
ROM_MAX_SIZE = 0x2b0000		//2,7MB free rom space
MAXFILES	 = 1024

IPC			= ipc_region
IPC_TOUCH_X		= IPC+0
IPC_TOUCH_Y		= IPC+4
IPC_KEYS		= IPC+8
IPC_MEMTBL		= IPC+16
IPC_REG4015		= IPC+32
IPC_APUIRQ		= IPC+33	// Not implemented yet.

KEY_A			= 1
KEY_B			= 2
KEY_SELECT		= 4
KEY_START		= 8
KEY_RIGHT		= 16
KEY_LEFT		= 32
KEY_UP			= 64
KEY_DOWN		= 128
KEY_R			= 256
KEY_L			= 512
KEY_X			= 1024
KEY_Y			= 2048
KEY_TOUCH		= 4096

		;@ Miscellaneous stuff

NDS_VRAM		= 0x6000000
NDS_OAM			= 0x7000000
NDS_BG			= 0x607C000
NDS_OBJVRAM		= 0x6400000
;@-----------

REG_BASE		= 0x4000000
REG_DISPCNT		= 0x00
REG_DISPSTAT	= 0x04
REG_BG0CNT		= 0x08
REG_BG0HOFS		= 0x10
REG_BG0VOFS		= 0x12
REG_BG1HOFS		= 0x14
REG_BG1VOFS		= 0x16
REG_DM0SAD		= 0xB0
REG_DM0DAD		= 0xB4
REG_DM0CNT_L	= 0xB8
REG_DM0CNT_H	= 0xBA
REG_DM1SAD		= 0xBC
REG_DM1DAD		= 0xC0
REG_DM1CNT_L	= 0xC4
REG_DM1CNT_H	= 0xC6
REG_DM2SAD		= 0xC8
REG_DM2DAD		= 0xCC
REG_DM2CNT_L	= 0xD0
REG_DM2CNT_H	= 0xD2
REG_DM3SAD		= 0xD4
REG_DM3DAD		= 0xD8
REG_DM3CNT_L	= 0xDC
REG_DM3CNT_H	= 0xDE
REG_IME			= 0x208
REG_IE			= 0x210
REG_IF			= 0x214
REG_WININ		= 0x48
REG_WINOUT		= 0x4A
REG_WIN0H		= 0x40
REG_WIN0V		= 0x44
REG_WIN1H		= 0x42
REG_WIN1V		= 0x46
REG_BLDCNT		= 0x50
REG_BLDALPHA	= 0x52

;@ Everything in wram_globals* areas:

globalptr	.req r10	;@ =wram_globals* ptr

	.struct 0					;@ M6502.s
rp2A03struct:	.space rp2A03Size
rp2C02struct:	.space rp2C02Size
mapperData:		.space 96

romBase:		.word 0
romMask:		.word 0
prgSize8k:		.word 0
prgSize16k:		.word 0
prgSize32k:		.word 0
mapperNr:		.word 0
emuFlags:		.word 0
prgcrc:			.word 0

lightY:			.word 0

renderCount:	.word 0
tempData:		.space 20*4

cartFlags:		.byte 0
subMapper:		.byte 0
padding:		.skip 2 ;@ Align
nesMachineSize:

;@-----------------------joyflags
P1_ENABLE		= 0x10000
P2_ENABLE		= 0x20000
B_A_SWAP		= 0x80000
L_R_DISABLE		= 0x100000
AUTOFIRE		= 0x1000000
;@-----------------------cartFlags
MIRROR			= 0x01 ;@ horizontal mirroring
SRAM			= 0x02 ;@ save SRAM
TRAINER			= 0x04 ;@ trainer present
SCREEN4			= 0x08 ;@ 4way screen layout
VS				= 0x10 ;@ VS unisystem
;@-----------------------emuFlags (keep c_defs.h updated)

NOFLICKER		= 1		;@ Flags&3:  0=flicker 1=noflicker 2=alphalerp
ALPHALERP		= 2
PALTIMING		= 4		;@ 0=NTSC 1=PAL
FOLLOWMEM		= 32  	;@ 0=follow sprite, 1=follow mem
SPLINE			= 64
SOFTRENDER		= 128
ALLPIXEL		= 256
NEEDSRAM		= 512
AUTOSRAM		= 1024
SCREENSWAP		= 0x800
LIGHTGUN		= 0x1000
MICBIT			= 0x2000
PALSYNC			= 0x4000
STRONGSYNC		= 0x8000
SYNC_NEED		= 0x18000
PALSYNC_BIT		= 0x10000
FASTFORWARD		= 0x20000
REWIND			= 0x40000
ALLPIXELON		= 0x80000
NSFFILE			= 0x100000
DISKBIOS		= 0x200000


;@------------------------multi-players
;@ In every frame, 64bit should be transfered. 32bit = IPC_KEYS, 32bit = CONTROL_BIT

MP_KEY_MSK		= 0x0CFF		;@ Not all the keys can be transfered.
MP_HOST			= (1 << 31)		;@ Whether I am a host.
MP_CONN			= (1 << 30)		;@ When communicating, kill this bit HIGH.
MP_RESET		= (1 << 29)		;@ Means that someone want to reset the game.
MP_NFEN			= (1 << 28)		;@ nifi is enabled.

MP_TIME_MSK		= 0xFFFF		;@ To sync the time.
MP_TIME			= 16			;@ 16 bits. counting the frames past.


				;@ Bits 8-15=scale type

UNSCALED_NOAUTO	= 0	@display types
UNSCALED_AUTO	= 1
SCALED			= 2
SCALED_SPRITES	= 3

				;@ Bits 16-31=sprite follow val

;@------------------------------------------------------------------------------
;@ [ DEBUG
;@	IMPORT debuginfo
;@ ]

ERR0	= 0
ERR1	= 1
READ	= 2
WRITE	= 3
BRK		= 4
BADOP	= 5
VBLS	= 6
FPS		= 7
BGMISS	= 8
CARTFLAG= 9

ALIVE	= 13
TMP0	= 14
TMP1	= 15
MAPPER	= 16
PRGCRC	= 17
DISKNO	= 18
MAKEID	= 19
GAMEID	= 20
EMUFLAG	= 21



;@ Not sure about stuff below, instructions???
.macro DEBUGINFO index,reg
	.if DEBUG
		stmfd sp!,{r9}
		ldr r9,=debuginfo
		str \reg,[r9,#\index*4]
		ldmfd sp!,{r9}
	.endif
.endm
	

.macro DEBUGCOUNT index
	.if DEBUG
		stmfd sp!,{r9-r10}
		ldr r9,=debuginfo
		ldr r10,[r9,#\index*4]
		add r10,r10,#1
		str r10,[r9,#\index*4]
		ldmfd sp!,{r9-r10}
	.endif
.endm

.macro DEBUGERROR addr,reg
	DEBUGINFO ERR0,\reg
    .if DEBUG
		ldr r1,=\addr
	.endif
	DEBUGINFO ERR1,r1
.endm

.macro SET_PID reg
	.if DEBUG
		mcr p15,0,\reg,c13,c0,1
	.endif
.endm

;@----------------
;@	END
