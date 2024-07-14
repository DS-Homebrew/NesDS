@---------------------------------------------------------------------------------
	#include "equates.h"
	#include "M6502mac.h"
@---------------------------------------------------------------------------------
	.global map67_
	.global map89_
	.global mapAB_
	.global mapCD_
	.global mapEF_
	.global map89AB_
	.global mapCDEF_
	.global map89ABCDEF_
	.global initcart
	.global NES_reset
	.global savestate
	.global loadstate
	.global globals
	.global rp2A03
@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
mappertbl:
	.word 0,mapper0init
	.word 1,mapper1init
	.word 2,mapper2init
	.word 3,mapper3init
	.word 4,mapper4init
	.word 5,mapper5init
	.word 7,mapper7init
	.word 9,mapper9init			@mapper9init does almost the same thing with mapper10init
	.word 10,mapper10init
	.word 11,mapper11init
	.word 15,mapper15init
	.word 16,mapper16init
	.word 17,mapper17init
	.word 18,mapper18init
	.word 19,mapper19init
	.word 20,mapper20init
	.word 21,mapper21init
	.word 22,mapper22init
	.word 23,mapper23init
	.word 24,mapper24init
	.word 25,mapper25init
	.word 26,mapper26init
	.word 30,mapper30init
	.word 32,mapper32init
	.word 33,mapper33init
	.word 34,mapper34init
	.word 40,mapper40init
	.word 42,mapper42init
	.word 47,mapper47init
	.word 48,mapper48init
	.word 64,mapper64init
	.word 65,mapper65init
	.word 66,mapper66init
	.word 67,mapper67init
	.word 68,mapper68init
	.word 69,mapper69init
	.word 70,mapper70init
	.word 71,mapper71init
	.word 72,mapper72init
	.word 73,mapper73init
	.word 74,mapper74init
	.word 75,mapper75init
	.word 76,mapper76init
	.word 77,mapper77init
	.word 78,mapper78init
	.word 79,mapper79init
	.word 80,mapper80init
	.word 85,mapper85init
	.word 86,mapper86init
	.word 87,mapper87init
	.word 90,mapper90init
	.word 91,mapper91init
	.word 92,mapper92init
	.word 93,mapper93init
	.word 94,mapper94init
	.word 97,mapper97init
	.word 99,mapper99init
	.word 105,mapper105init
	.word 111,mapper111init
	.word 118,mapper118init
	.word 119,mapper4init
	.word 140,mapper66init
	.word 148,mapper148init
	.word 151,mapper151init
	.word 152,mapper152init
	.word 153,mapper16init
	.word 157,mapper16init
	.word 158,mapper64init
	.word 159,mapper159init
	.word 163,mapper163init
	.word 180,mapper180init
	.word 184,mapper184init
	.word 189,mapper189init
	.word 198,mapper198init
	.word 216,mapper216init
	.word 225,mapper225init
	.word 226,mapper226init
	.word 227,mapper227init
	.word 228,mapper228init
	.word 229,mapper229init
	.word 230,mapper230init
	.word 231,mapper231init
	.word 232,mapper232init
	.word 240,mapper240init
	.word 245,mapper245init
	.word 246,mapper246init
	.word 252,mapper252init
	.word 253,mapper253init
	.word 255,mapper255init
	.word 256,mappernsfinit
	.word -1,mapper0init
@---------------------------------------------------------------------------------
@ name:		initcart
@ function:	program starts from here.
@ arguments:	none
@ description:	none

initcart: @called from C:  r0=rom, (r1=emuFlags?)
@
@	(initialize mapper, etc after loading the rom)
@---------------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}

	ldr globalptr,=globals	@ init ptr regs
	ldr m6502zpage,=NES_RAM

	ldr_ r1,emuFlags
	tst r1, #NSFFILE
	addeq r3,r0,#16			@ skip over iNES header
	addne r3, r0, #128		@ skip nsf file header
	str_ r3,romBase			@ set rom base.  r3=romBase til end of initcart

	mov r2,#1
	ldrb r1,[r3,#-12]		@ r1 = 16K PRG-ROM page count
	movne r1, #1			@ nsf has 16k?
	str_ r1,prgSize16k		@ some games' prg rom not == to (2**n), shit...
	mov r0, r1, lsl#1
	str_ r0,prgSize8k
	mov r0, r1, lsr#1
	str_ r0,prgSize32k

	rsb r0,r2,r1,lsl#14		@ r0 = page count * 16K - 1
	str_ r0,romMask			@ romMask=romSize-1

	add r0,r3,r1,lsl#14		@ r0 = rom end.(romsize + rom start)
	str_ r0,vromBase		@ set vrom base

	ldrb r4,[r3,#-11]		@ 8K CHR-ROM page count
	movne r4, #0			@ nsf has none?
	mov r1,r4				@ r1=vrom size
	cmp r4,#2				@ round up
	movhi r1,#4				@ needs to be power of 2 (stupid zelda2)
	cmp r4,#4
	movhi r1,#8
	cmp r4,#8
	movhi r1,#16
	cmp r4,#16
	movhi r1,#32
	cmp r4,#32
	movhi r1,#64
	cmp r4,#64
	movhi r1,#128
	rsbs r0,r2,r1,lsl#13	@ r0 = VROM page size * 8K - 1
	str_ r0,vromMask		@ vromMask=vromSize-1
	ldrmi r0,=NES_VRAM
	strmi_ r0,vromBase		@ vromBase=NES VRAM if vromSize=0

	ldr r0,=void
	ldrmi r0,=VRAM_chr		@ enable/disable chr write
	ldr r1,=vram_write_tbl	@ set the first 8 function pointers to 'void'?
	mov r2,#8
	bl filler

	stmfd sp!, {r3, r12}
	mov r0, #0				@ init val, cal crc for prgrom
	ldr_ r1, romBase		@ src
	ldr_ r2, prgSize8k		@ size
	mov r2, r2, lsl#13
	swi 0x0e0000			@ swicrc16
	str_ r0, prgcrc
	DEBUGINFO PRGCRC, r0
	ldmfd sp!, {r3, r12}

	mov m6502pc,#0			@ (eliminates any encodePC errors during mapper*init)
	str_ m6502pc,m6502LastBank

	ldr_ r1,emuFlags
	tst r1, #NSFFILE
	bne 0f
	mov r0,#0				@ default ROM mapping
	bl map89AB_				@ 89AB=1st 16k
	mov r0,#-1
	bl mapCDEF_				@ CDEF=last 16k
0:
	bl resetCHR				@ default CHR mapping

	ldrb r0,[r3,#-10]		@ rom control byte #1
	ldrb r1,[r3,#-9]		@ rom control byte #2
	and r0,r0,#0x0f			@ exclude mapper
	orr r1,r0,r1,lsl#4
	strb_ r1,cartFlags		@ set cartFlags(upper 4-bits (<<8, ignored) + 0000(should be zero)(<<4) + vTsM)
	@DEBUGINFO CARTFLAG, r1

	ldr r0,=void
	str_ r0,scanlineHook	@ no mapper irq

	mov r0,#0x0				@ clear nes ram		reset value changed from 0xFFFFFFFF to 0x0
	mov r1,m6502zpage		@ m6502zpage,=NES_RAM
	mov r2,#0x800/4			
	bl filler				@ reset NES RAM
	mov r0,#0				@ clear nes sram
	add r1,m6502zpage,#0x800	@ save ram = SRAM
	mov r2,#0x2000/4
	bl filler
	adrl_ r1,mapperData		@ clear mapperData so we dont have to do that in every MapperInit.
	mov r2,#96/4
	bl filler

	mov r0,#0x7c			@ I didnt like the way below to change the init mem for fixing some games.
	mov r1,m6502zpage
	ldr r2,=0x247d			@ 0x7c7d
	strb r0,[r1,r2]			@ for "Low G Man".
	add r2,r2,#0x100
	mov r0,#0x7d
	strb r0,[r1,r2]			@ for "Low G Man".

	ldr r1,=void
	str_ r1, newFrameHook
	str_ r1, endFrameHook
	@str_ r1, hblankHook
	str_ r1, ppuChrLatch

	ldr r0, =0x4000004
	mov r1, #0x8
	strh r1, [r0]			@ disable hblank process.

	@ Setup read mem table
	ldr r1,=ram_R
	str_ r1,m6502ReadTbl+0
	ldr r1,=PPU_R
	str_ r1,m6502ReadTbl+4
	ldr r1,=empty_R
	str_ r1,rp2A03MemRead
	ldr r1,=mem_R60
	str_ r1,m6502ReadTbl+12
	ldr r1,=rom_R80
	str_ r1,m6502ReadTbl+16
	ldr r1,=rom_RA0
	str_ r1,m6502ReadTbl+20
	ldr r1,=rom_RC0
	str_ r1,m6502ReadTbl+24
	ldr r1,=rom_RE0
	str_ r1,m6502ReadTbl+28


	@ Setup write mem table
	ldr r1,=ram_W
	str_ r1,m6502WriteTbl+0
	ldr r1,=PPU_W
	str_ r1,m6502WriteTbl+4
	ldr r1,=empty_W
	str_ r1,rp2A03MemWrite
	ldr r1,=sram_W
	str_ r1,m6502WriteTbl+12
	ldr r1,=rom_W
	str_ r1,m6502WriteTbl+16
	ldr r1,=rom_W
	str_ r1,m6502WriteTbl+20
	ldr r1,=rom_W
	str_ r1,m6502WriteTbl+24
	ldr r1,=rom_W
	str_ r1,m6502WriteTbl+28

	ldr r1,=NES_RAM
	str_ r1,m6502MemTbl+0
	ldr r1,=NES_XRAM-0x2000
	str_ r1,m6502MemTbl+4
	ldr r1,=NES_XRAM-0x4000
	str_ r1,m6502MemTbl+8
	ldr r1,=NES_RAM-0x5800	@ $6000 for mapper 40, 69 & 90 that has rom here.
	str_ r1,m6502MemTbl+12

	ldrb r1,[r3,#-10]		@ get mapper#
	ldrb r2,[r3,#-9]
	tst r2,#0x0e			@ long live DiskDude!
	and r1,r1,#0xf0
	and r2,r2,#0xf0
	orr r0,r2,r1,lsr#4
	movne r0,r1,lsr#4		@ ignore high nibble if header looks bad
					@lookup mapper*init

	ldrb r1, [r3, #-16]		@ fds, for 'F'
	cmp r1, #70
	ldreqb r1, [r3, #-15]	@ fds, for 'D'
	cmpeq r1, #68
	ldreqb r1, [r3, #-14]	@ fds, for 'S'
	cmpeq r1, #83
	moveq r0, #20			@ this is a fds file...

	ldr_ r1,emuFlags
	tst r1, #NSFFILE
	movne r0, #256

	ldr r1,=mappertbl
@---
	DEBUGINFO MAPPER r0
@---
lc0:	ldr r2,[r1],#8
	teq r2,r0
	beq lc1
	bpl lc0
lc1:					@ call mapperXXinit
	adr_ r5,m6502WriteTbl+16
	ldr r0,[r1,#-4]		@ r0 = mapperxxxinit
	ldmia r0!,{r1-r4}
	stmia r5,{r1-r4}	@ set default (write) operation for NES(0x8000 ~ 0xFFFF), maybe 'void', according to Mapper.
	blx r0				@ go mapper_init

	ldrb_ r1,cartFlags
	tst r1,#MIRROR		@ set default mirror, horizontal mirroring
	bl mirror2H_		@ (call after mapperinit to allow mappers to set up cartFlags first)

	bl NES_reset
	bl recorder_reset	@ init rewind control stuff

	ldmfd sp!,{r4-r11,pc}
@---------------------------------------------------------------------------------
savestate:
@int savestate(void *here): copy state to <here>, return size
@---------------------------------------------------------------------------------
	stmfd sp!,{r4-r6,globalptr,lr}

	ldr globalptr,=globals

	ldr_ r2,romBase
	rsb r2,r2,#0			@ adjust rom maps,etc so they aren't based on romBase
	bl fixromptrs

	mov r6,r0			@ r6=where to copy state
	mov r0,#0			@ r0 holds total size (return value)

	adr r4,savelst			@ r4=list of stuff to copy
	mov r3,#(lstend-savelst)/8	@ r3=items in list
ss1:
	ldr r2,[r4],#4				@ r2=what to copy
	ldr r1,[r4],#4				@ r1=how much to copy
	add r0,r0,r1
ss0:
	ldr r5,[r2],#4
	str r5,[r6],#4
	subs r1,r1,#4
	bne ss0
	subs r3,r3,#1
	bne ss1

	ldr_ r2,romBase			@ restore pointers
	bl fixromptrs

	ldmfd sp!,{r4-r6,globalptr,pc}

savelst: .word NES_RAM,0x2800
	.word NES_VRAM,0x3000
	.word agb_pal,96
	.word vram_map,64
	.word agb_nt_map,16
	.word globals+mapperData,96
	.word globals+m6502MemTbl+4*4,16
	.word globals+m6502StateStart,44
	.word globals+ppuState,64
lstend:
@c_defs: #define SAVESTATESIZE (0x2800+0x3000+96+64+16+96+16+44+64)

fixromptrs:	@add r2 to some things
	adr_ r1,m6502MemTbl+4*4
	ldmia r1,{r3-r6}
	add r3,r3,r2
	add r4,r4,r2
	add r5,r5,r2
	add r6,r6,r2
	stmia r1,{r3-r6}

	ldr_ r3,m6502LastBank
	add r3,r3,r2
	str_ r3,m6502LastBank

	ldr_ r3,m6502RegPC
	add r3,r3,r2
	str_ r3,m6502RegPC

	bx lr
@---------------------------------------------------------------------------------
loadstate:
@void loadstate(u32 *stateptr)	 (stateptr must be word aligned)
@---------------------------------------------------------------------------------
	stmfd sp!,{r0,r4-r7,globalptr,lr}

	ldr globalptr,=globals
	bl resetCHR
	ldmfd sp!,{r6}			@r6=where state is at

	mov r0,#(lstend-savelst)/8	@read entire state
	adr r4,savelst
ls1:	ldr r2,[r4],#4
	ldr r1,[r4],#4
ls0:	ldr r5,[r6],#4
	str r5,[r2],#4
	subs r1,r1,#4
	bne ls0
	subs r0,r0,#1
	bne ls1

	ldr_ r2,romBase		@adjust ptr shit (see savestate above)
	bl fixromptrs
@---
	ldr r3,=NES_VRAM+0x2000		@write all nametbl + attrib
	ldr r4,=NDS_BG
ls4:	mov r5,#0
ls3:	mov r1,r3
	mov r2,r4
	mov addy,r5
	ldrb r0,[r1,addy]
	@sub sp, sp, #4			@This is because writeBG will use ldmfd sp!,{addy}, out of date
	bl writeBG
	add r5,r5,#1
	cmp r5,#0x400
	bne ls3
	add r3,r3,#0x400
	add r4,r4,#0x800
	tst r4,#0x1800
	bne ls4
@---
	@ldr r0,nesChrMap		@init BG CHR
	@bl bg_chr_req
	@ldr r0,nesChrMap+4
	@bl bg_chr_req
	bl updateBGCHR
	ldrb_ r0,ppuCtrl1
	bl ctrl1_W

	ldmfd sp!,{r4-r7,globalptr,pc}
@---------------------------------------------------------------------------------
NES_reset:
@---------------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}

	ldr globalptr,=globals		@need this?
	ldr m6502zpage,=NES_RAM

	bl PPU_reset
	ldr r0,=rp2A03SetNMIPin
	str_ r0,ppuIrqFunc
	bl IO_reset
	bl Sound_reset
	bl CPU_reset
	
	bl nespatch

	ldmfd sp!,{r4-r11,pc}
@---------------------------------------------------------------------------------
map67_:	@rom paging.. r0=page#
@---------------------------------------------------------------------------------
	ldr_ r1,romBase
	sub r1,r1,#0x6000
	ldr_ r2,prgSize8k
	tst r0, #0x80000000
	addne r0, r0, r2
0:
	cmp r0, r2
	subcs r0, r0, r2
	bcs 0b
	add r0,r1,r0,lsl#13
	str_ r0,m6502MemTbl+12
	b flush
@---------------------------------------------------------------------------------
map89_:	@rom paging.. r0=page#
@---------------------------------------------------------------------------------
	ldr_ r1,romBase
	sub r1,r1,#0x8000
	ldr_ r2,prgSize8k
	tst r0, #0x80000000
	addne r0, r0, r2
0:
	cmp r0, r2
	subcs r0, r0, r2
	bcs 0b
	add r0,r1,r0,lsl#13
	str_ r0,m6502MemTbl+16
	b flush
@---------------------------------------------------------------------------------
mapAB_:
@---------------------------------------------------------------------------------
	ldr_ r1,romBase
	sub r1,r1,#0xa000
	ldr_ r2,prgSize8k
	tst r0, #0x80000000
	addne r0, r0, r2
0:
	cmp r0, r2
	subcs r0, r0, r2
	bcs 0b
	add r0,r1,r0,lsl#13
	str_ r0,m6502MemTbl+20
	b flush
@---------------------------------------------------------------------------------
mapCD_:
@---------------------------------------------------------------------------------
	ldr_ r1,romBase
	sub r1,r1,#0xc000
	ldr_ r2,prgSize8k
	tst r0, #0x80000000
	addne r0, r0, r2
0:
	cmp r0, r2
	subcs r0, r0, r2
	bcs 0b
	add r0,r1,r0,lsl#13
	str_ r0,m6502MemTbl+24
	b flush
@---------------------------------------------------------------------------------
mapEF_:
@---------------------------------------------------------------------------------
	ldr_ r1,romBase
	sub r1,r1,#0xe000
	ldr_ r2,prgSize8k
	tst r0, #0x80000000
	addne r0, r0, r2
0:
	cmp r0, r2
	subcs r0, r0, r2
	bcs 0b
	add r0,r1,r0,lsl#13
	str_ r0,m6502MemTbl+28
	b flush
@---------------------------------------------------------------------------------
map89AB_:
@---------------------------------------------------------------------------------
	ldr_ r1,romBase
	sub r1,r1,#0x8000
	ldr_ r2,prgSize16k
	tst r0, #0x80000000
	addne r0, r0, r2
0:
	cmp r0, r2
	subcs r0, r0, r2
	bcs 0b
	add r0,r1,r0,lsl#14
	str_ r0,m6502MemTbl+16
	str_ r0,m6502MemTbl+20
flush:		@update m6502pc & m6502LastBank
	ldr_ r1,m6502LastBank
	sub m6502pc,m6502pc,r1
	b translate6502PCToOffset	;@ In=m6502pc, Out=m6502pc,r0=lastBank
@---------------------------------------------------------------------------------
mapCDEF_:
@---------------------------------------------------------------------------------
	ldr_ r1,romBase
	sub r1,r1,#0xc000
	ldr_ r2,prgSize16k
	tst r0, #0x80000000
	addne r0, r0, r2
0:
	cmp r0, r2
	subcs r0, r0, r2
	bcs 0b
	add r0,r1,r0,lsl#14
	str_ r0,m6502MemTbl+24
	str_ r0,m6502MemTbl+28
	b flush
@---------------------------------------------------------------------------------
map89ABCDEF_:
@---------------------------------------------------------------------------------
	ldr_ r1,romBase
	sub r1,r1,#0x8000
	ldr_ r2,prgSize32k
	tst r0, #0x80000000
	addne r0, r0, r2
0:
	cmp r0, r2
	subcs r0, r0, r2
	bcs 0b
	add r0,r1,r0,lsl#15
	str_ r0,m6502MemTbl+16
	str_ r0,m6502MemTbl+20
	str_ r0,m6502MemTbl+24
	str_ r0,m6502MemTbl+28
	b flush
@---------------------------------------------------------------------------------

.section .dtcm, "aw"
globals:
nesMachine:
rp2A03:
	.skip nesMachineSize
