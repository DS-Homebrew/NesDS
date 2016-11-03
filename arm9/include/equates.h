@		GBLL DEBUG
@	VERSION_IN_ROM = 0  @out of pocketnes ??
	#include "macro.h"
DEBUG		= 1
DEBUGSTEP	= 0
@----------------------------------------------------------------------------

wram = NES_DRAM	//64k ram is reserved here.
ROM_MAX_SIZE = 0x318000
MAXFILES	 = 1024

IPC			= ipc_region
IPC_TOUCH_X		= IPC+0
IPC_TOUCH_Y		= IPC+4
IPC_KEYS		= IPC+8
IPC_MEMTBL		= IPC+16
IPC_REG4015		= IPC+32
IPC_APUIRQ		= IPC+33	//not implemented yet.

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

		@DMA buffers go in high RAM - stay below 27ffc00 (firmware settings)
.global nes_region
.global ct_buffer

DISPCNTBUFF		= ct_buffer
BGCNTBUFF		= DISPCNTBUFF + 512*4			@size is 240*16
BGCNTBUFFB		= BGCNTBUFF + 256 * 16

		@miscellaneous stuff
		
NES_RAM			= nes_region	@keep $400 byte aligned for 6502 stack
NES_SRAM		= NES_RAM+0x0800	@***!!! also in c_defs.h
NES_VRAM		= NES_SRAM+0x2000
NES_XRAM		= NES_VRAM+0x3000
CHR_DECODE		= NES_XRAM+0x2000
MAPPED_RGB		= CHR_DECODE+0x400
NES_SPRAM		= MAPPED_RGB+0x100	@mapped NES palette (for VS unisys)
@?			EQU MAPPED_RGB+64*3
			
NDS_PALETTE		= 0x5000000
NDS_VRAM		= 0x6000000
NDS_SRAM		= 0xA000000
NDS_OAM			= 0x7000000
NDS_BG			= 0x607C000
NDS_OBJVRAM		= 0x6400000
@-----------

REG_BASE		= 0x4000000
REG_DISPCNT		= 0x00
REG_DISPSTAT		= 0x04
REG_BG0CNT		= 0x08
REG_BG0HOFS		= 0x10
@REG_BG0VOFS		EQU 0x12
@REG_BG1HOFS		EQU 0x14
@REG_BG1VOFS		EQU= 0x16
REG_DM0SAD		= 0xB0
REG_DM0DAD		= 0xB4
REG_DM0CNT_L		= 0xB8
REG_DM0CNT_H		= 0xBA
REG_DM1SAD		= 0xBC
REG_DM1DAD		= 0xC0
REG_DM1CNT_L		= 0xC4
REG_DM1CNT_H		= 0xC6
REG_DM2SAD		= 0xC8
REG_DM2DAD		= 0xCC
REG_DM2CNT_L		= 0xD0
REG_DM2CNT_H		= 0xD2
REG_DM3SAD		= 0xD4
REG_DM3DAD		= 0xD8
REG_DM3CNT_L		= 0xDC
REG_DM3CNT_H		= 0xDE
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
REG_BLDALPHA		= 0x52

		@r0,r1,r2=temp regs
m6502_nz	.req r3 @bit 31=N, Z=1 if bits 0-7=0
m6502_rmem	.req r4 @readmem_tbl
m6502_a		.req r5 @bits 0-23=0, also used to clear bytes in memory
m6502_x		.req r6 @bits 0-23=0
m6502_y		.req r7 @bits 0-23=0
cycles		.req r8 @also VDIC flags
m6502_pc	.req r9
globalptr	.req r10 @=wram_globals* ptr
m6502_optbl	.req r10
cpu_zpage	.req r11 @=CPU_RAM
addy		.req r12 @keep this at r12 (scratch for APCS)
		@r13=SP
		@r14=LR
		@r15=PC
@----------------------------------------------------------------------------

@start_map 0,cpu_zpage
@_m_ nes_ram,0x800
@_m_ nes_sram,0x2000
@_m_ chr_decode,0x400

@everything in wram_globals* areas:

start_map 0,globalptr	@6502.s
_m_ opz,256*4
_m_ readmem_tbl,8*4
_m_ writemem_tbl,8*4
_m_ memmap_tbl,8*4
_m_ cpuregs,7*4
_m_ m6502_s,4
_m_ lastbank,4
_m_ nexttimeout,4
_m_ scanline,4
_m_ scanlinehook,4
_m_ frame,4
_m_ cyclesperscanline,4
_m_ lastscanline,4
_m_ unused_align,4
			@ppu.s
_m_ fpsvalue,4
_m_ adjustblend,4
 @ppustate:
_m_ vramaddr,4
_m_ vramaddr2,4
_m_ scrollX,4
_m_ scrollY,4
_m_ scrollYtemp,4
_m_ sprite0y,4
_m_ readtemp,4
_m_ bg0cnt,4
_m_ sprite0x,1
_m_ vramaddrinc,1
_m_ ppustat,1
_m_ toggle,1
_m_ ppuctrl0,1
_m_ ppuctrl0frame,1
_m_ ppuctrl1,1
_m_ ppuoamadr,1
_m_ nes_chr_map,16

_m_ vrommask,4
_m_ vrombase,4

			@cart.s
_m_ newframehook,4
_m_ endframehook,4
_m_ hblankhook,4
_m_ ppuchrlatch,4
_m_ mapperdata,96
_m_ rombase,4

_m_ rommask,4     @ADDED
_m_ romnumber,4   @ADDED
_m_ prgsize8k,4     @ADDED
_m_ prgsize16k,4     @ADDED
_m_ prgsize32k,4     @ADDED
_m_ emuflags,4 @ADDED
_m_ prgcrc,4

_m_ lighty,4

_m_ loopy_t,4
_m_ loopy_x,4
_m_ loopy_y,4
_m_ loopy_v,4
_m_ loopy_shift,4
_m_ bglastline, 4
_m_ rendercount, 4
_m_ tempdata, 20*4

_m_ nsfid, 5
_m_ nsfversion, 1
_m_ nsftotalsong, 1
_m_ nsfstartsong, 1
_m_ nsfloadaddress, 2
_m_ nsfinitaddress, 2
_m_ nsfplayaddress, 2
_m_ nsfsongname, 32
_m_ nsfartistname, 32
_m_ nsfcopyrightname, 32
_m_ nsfspeedntsc, 2
_m_ nsfbankswitch, 8
_m_ nsfspeedpal, 2
_m_ nsfntscpalbits, 1
_m_ nsfextrachipselect, 1
_m_ nsfexpansion, 4
_m_ nsfplay, 4
_m_ nsfinit, 4
_m_ nsfsongno, 4
_m_ nsfsongmode, 4

_m_ pixstart, 4
_m_ pixend, 4

_m_ af_st, 4	@auto fire state
_m_ af_start, 4 @auto fire start
_m_ palsyncline, 4

_m_ cartflags,1 @ADDED
_m_ barcode, 1
_m_ barcode_out, 1
@_m_ ,1 @align   @ADDED

@----------------------------------------------------------------------------
IRQ_VECTOR		= 0xfffe @ IRQ/BRK interrupt vector address
RES_VECTOR		= 0xfffc @ RESET interrupt vector address
NMI_VECTOR		= 0xfffa @ NMI interrupt vector address
@-----------------------joyflags
P1_ENABLE		= 0x10000
P2_ENABLE		= 0x20000
B_A_SWAP		= 0x80000
L_R_DISABLE		= 0x100000
AUTOFIRE		= 0x1000000
@-----------------------cartflags
MIRROR			= 0x01 @horizontal mirroring
SRAM			= 0x02 @save SRAM
TRAINER			= 0x04 @trainer present
SCREEN4			= 0x08 @4way screen layout
VS			= 0x10 @VS unisystem
@-----------------------emuflags (keep c_defs.h updated)

NOFLICKER		= 1	@flags&3:  0=flicker 1=noflicker 2=alphalerp
ALPHALERP		= 2
PALTIMING		= 4	@0=NTSC 1=PAL
FOLLOWMEM		= 32  @0=follow sprite, 1=follow mem
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
@?			EQU 64
@?			EQU 128


@------------------------multi-players
@in everyframe, 64bit sould be transfered. 32bit = IPC_KEYS, 32bit = CONTROL_BIT

MP_KEY_MSK		= 0x0CFF			@not all the keys can be transfered.
MP_HOST			= (1 << 31)			@whether I am a host.
MP_CONN			= (1 << 30)			@when communicating, kill this bit HIGH.
MP_RESET		= (1 << 29)			@means that someone want to reset the game.
MP_NFEN			= (1 << 28)			@nifi is enabled.

MP_TIME_MSK		= 0xFFFF			@to sync the time.
MP_TIME			= 16				@16 bits. counting the frames past.					


				@bits 8-15=scale type

UNSCALED_NOAUTO	= 0	@display types
UNSCALED_AUTO	= 1
SCALED		= 2
SCALED_SPRITES	= 3

				@bits 16-31=sprite follow val

@----------------------------------------------------------------------------
CYC_SHIFT		= 8
CYCLE			= 1<<CYC_SHIFT @one cycle (341*CYCLE cycles per scanline)

@cycle flags- (stored in cycles reg for speed)

CYC_C			= 0x01	@Carry bit
BRANCH			= 0x02	@branch instruction encountered
CYC_I			= 0x04	@IRQ mask
CYC_D			= 0x08	@Decimal bit
CYC_V			= 0x40	@Overflow bit
CYC_MASK		= CYCLE-1	@Mask
@------------------------------------------------------------------------------
@ [ DEBUG
@	IMPORT debuginfo
@ ]

ERR0	= 0
ERR1	= 1
READ	= 2
WRITE	= 3
BRK	= 4
BADOP	= 5
VBLS	= 6
FPS	= 7
BGMISS	= 8
CARTFLAG= 9


MAPPER	= 16
PRGCRC	= 17
DISKNO	= 18
MAKEID	= 19
GAMEID	= 20



@not sure about stuff below, instructions???
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

@----------------
@	END
