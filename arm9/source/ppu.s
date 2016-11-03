@---------------------------------------------------------------------------------
	#include "equates.h"
@---------------------------------------------------------------------------------
	.global scaletable
	.global PPU_init
	.global PPU_reset
	.global PPU_R
	.global PPU_W
	.global agb_nt_map
	.global vram_map
	.global vram_write_tbl
	.global VRAM_chr
	.global newframe
	.global agb_pal
	.global writeBG
	.global ctrl1_W
	.global EMU_VBlank
	.global ppusync
	.global rescale_nr
	.global bg_chr_req
	.global chr0_
	.global chr1_
	.global chr2_
	.global chr3_
	.global chr4_
	.global chr5_
	.global chr6_
	.global chr7_
	.global chr01_
	.global chr23_
	.global chr45_
	.global chr67_
	.global chr0123_
	.global chr4567_
	.global chr01234567_
	.global cram1k
	.global updateBGCHR
	.global updateOBJCHR
	.global mirror1H_
	.global mirror1_
	.global mirror2V_
	.global mirror2H_
	.global mirror4_
	.global mirrorKonami_
	.global mirror_xram_0000
	.global agb_bg_map
	.global resetCHR
	.global writeCHRTBL
	@.global unpack_tiles
	.global chr1k
	.global chr2k
	.global nes_nt0
	.global DMAline
	.global currentBG
	.global nextBG
	.global agb_bg_map
	.global agb_obj_map
	.global dispcnt
	.global spchr_update
	.global nes_palette
	.global vromnt1k
	.global gfx_scale
	.global nespal

@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
nes_rgb:
	.byte 117,117,117, 39,27,143, 0,0,171, 71,0,159, 143,0,119, 171,0,19, 167,0,0, 127,11,0
	.byte 67,47,0, 0,71,0, 0,81,0, 0,63,23, 27,63,95, 0,0,0, 31,31,31, 5,5,5
	.byte 188,188,188, 0,115,239, 35,59,239, 131,0,243, 191,0,191, 231,0,91, 219,43,0, 203,79,15
	.byte 139,115,0, 0,151,0, 0,171,0, 0,147,59, 0,131,139, 49,49,49, 9,9,9, 9,9,9
	.byte 255,255,255, 63,191,255, 95,151,255, 167,139,253, 247,123,255, 255,119,183, 255,119,99, 255,155,59
	.byte 243,191,63, 131,211,19, 79,223,75, 88,248,152, 0,235,219, 102,102,102, 13,13,13, 13,13,13
	.byte 255,255,255, 171,231,255, 199,215,255, 215,203,255, 255,199,255, 255,199,219,255, 191,179,255, 219,171
	.byte 255,231,163, 227,255,163, 171,243,191, 179,255,207, 159,255,243, 209,209,209, 17,17,17, 17,17,17

DISPCNT_INIT = 0x38810010		@1D OBJ

@---------------------------------------------------------------------------------
remap_pal:
@---------------------------------------------------------------------------------
	ldr r5,=nes_rgb
	ldr r6,=MAPPED_RGB
	mov r7,#64*3
nomap:
	ldr r0,[r5],#4
	str r0,[r6],#4
	subs r7,r7,#4
	bne nomap
	mov pc,lr
.ltorg
@---------------------------------------------------------------------------------
paletteinit:@	r0-r3 modified.
@---------------------------------------------------------------------------------
	stmfd sp!,{r4-r8,lr}
	bl remap_pal
	ldr r8,=NDS_PALETTE+0x100
	ldr r6,=nespal
	mov r4,#64
gloop0:
	ldrh r0,[r6],#2
	strh r0,[r8],#2
	subs r4,r4,#1
	bne gloop0

	ldr r6,=MAPPED_RGB
	mov r7,r6
	mov r1,#0 @ldrb r1,gammavalue	;gamma value = 0 -> 4
	mov r4,#64			@pce rgb, r1=R, r2=G, r3=B
gloop:					@map 0bbbbbgggggrrrrr  ->  0bbbbbgggggrrrrr
	ldrb r0,[r6],#1
	bl gammaconvert
	mov r5,r0

	ldrb r0,[r6],#1
	bl gammaconvert
	orr r5,r5,r0,lsl#5

	ldrb r0,[r6],#1
	bl gammaconvert
	orr r5,r5,r0,lsl#10

	strh r5,[r7],#2
	strh r5,[r8],#2
	subs r4,r4,#1
	bne gloop

	ldmfd sp!,{r4-r8,lr}
	bx lr
.ltorg
@---------------------------------------------------------------------------------
gammaconvert:@	takes value in r0(0-0xFF), gamma in r1(0-4),returns new value in r0=0x1F
@---------------------------------------------------------------------------------
	rsb r2,r0,#0x100
	mul r3,r2,r2
	rsbs r2,r3,#0x10000
	rsb r3,r1,#4
	orr r0,r0,r0,lsl#8
	mul r2,r1,r2
	mla r0,r3,r0,r2
	mov r0,r0,lsr#13

	bx lr
@---------------------------------------------------------------------------------
PPU_init:	@only need to call once
@---------------------------------------------------------------------------------
	stmfd sp!,{lr}
	
	mov r1,#0xffffff00		@build chr decode table
	ldr r2,=CHR_DECODE
ppi0:	mov r0,#0
	tst r1,#0x01
	orrne r0,r0,#0x10000000
	tst r1,#0x02
	orrne r0,r0,#0x01000000
	tst r1,#0x04
	orrne r0,r0,#0x00100000
	tst r1,#0x08
	orrne r0,r0,#0x00010000
	tst r1,#0x10
	orrne r0,r0,#0x00001000
	tst r1,#0x20
	orrne r0,r0,#0x00000100
	tst r1,#0x40
	orrne r0,r0,#0x00000010
	tst r1,#0x80
	orrne r0,r0,#0x00000001
	str r0,[r2],#4
	adds r1,r1,#1
	bne ppi0


	mov r1,#0xffffff00		@build chr decode table
	ldr r2,=rev_data
ppi1:	mov r0,#0
	tst r1,#0x01
	orrne r0,r0,#0x80
	tst r1,#0x02
	orrne r0,r0,#0x40
	tst r1,#0x04
	orrne r0,r0,#0x20
	tst r1,#0x08
	orrne r0,r0,#0x10
	tst r1,#0x10
	orrne r0,r0,#0x08
	tst r1,#0x20
	orrne r0,r0,#0x04
	tst r1,#0x40
	orrne r0,r0,#0x02
	tst r1,#0x80
	orrne r0,r0,#0x01
	strb r0,[r2],#1
	adds r1,r1,#1
	bne ppi1

	ldr r0,=DISPCNT_INIT	@clear HDMA buffers
	ldr r1,=DISPCNTBUFF
	mov r2,#240
	bl filler
	mov r0,#0
	ldr r1,=BGCNTBUFF
	mov r2,#(240*16)/4
	bl filler

	mov r1,#REG_BASE
	ldr r0,=0x2f2c			@set up window for 8-pixel border on left edge
	strh r0,[r1,#REG_WININ]	@WIN0 masks BG+sprites, WIN1 masks sprites
	ldr r0,=0x3f3f			@(not 100% accurate because of priority weirdness, but close enough)
	strh r0,[r1,#REG_WINOUT]
	mov r0,#8
	strh r0,[r1,#REG_WIN0H]
	strh r0,[r1,#REG_WIN1H]
	mov r0,#192
	strh r0,[r1,#REG_WIN0V]	
	strh r0,[r1,#REG_WIN1V]
		
	ldmfd sp!,{pc}
.ltorg
@---------------------------------------------------------------------------------
rescale_nr:		@r0=scale, r1=starting Y<<16
@---------------------------------------------------------------------------------
	ldr r2,scale
	and r2,r2,#1
	bic r0,r0,#1
	orr r0,r0,r2
	str r0,scale
	str r1,DMAlinestart			@scaletable2 never used...
	
	stmfd sp!,{r4-r9,globalptr,lr}
	ldr globalptr,=globals
	ldr r3, =0x4000
	
		add r8,r1,r3
	mov r2,#0		@line counter
	adr r3,scaletable
		ldr r7,=scaletable2
		ldr r9,=spriteY_lookup2		@sprite need flicker too..
	ldr r5,=spriteY_lookup
	mov r6,#0		@zero

rs1:	movs r4,r1,asr#16
	strplb r4,[r3,r2]
	strmib r6,[r3,r2]
	@add r4, r4, #1				@I dont like this...
	strb r4,[r9,r2]
		movs r4,r8,asr#16
		strplb r4,[r7,r2]
		strmib r6,[r7,r2]
	@add r4,r4,#1
	strb r4,[r5,r2]
	add r1,r1,r0
		add r8,r8,r0
	add r2,r2,#1
	cmp r2,#256
	bcc rs1
		
	mov r1,#REG_BASE	@change blend control for scaling type
	@ldr r0,=emuflags
	@ldr r0,[r0]
	ldr_ r0,emuflags
	tst r0,#ALPHALERP
	ldrne r2,=0x08082241
	ldreq r2,=0x10000310
	str r2,[r1,#REG_BLDCNT]

	ldmfd sp!,{r4-r9,globalptr,pc}
.ltorg
@---------------------------------------------------------------------------------
PPU_reset:
@---------------------------------------------------------------------------------
	stmfd sp!,{lr}
	
	mov r0,#0
	strb_ r0,ppuctrl0	@NMI off
	strb_ r0,ppuctrl1	@screen off
	strb_ r0,ppustat		@flags off

	mov r0,#0
	ldr r1,=NES_VRAM
	mov r2,#0x3000/4
	bl filler		@clear nes VRAM

	mov r0,#0xe0
	mov r1,#NDS_OAM
	mov r2,#0x100
	bl filler		@clear OAM

	mov r0, #-1
	ldr r1, =bank_cache
	mov r2, #0x8
	bl filler

	bl paletteinit		@do palette mapping (for VS) & gamma
	
	ldmfd sp!,{pc}
.ltorg
@---------------------------------------------------------------------------------
EMU_VBlank:	@call every vblank
@---------------------------------------------------------------------------------
	stmfd sp!,{r4-r7,globalptr,lr}
	ldr globalptr,=globals

	ldrb_ r1,cartflags		@set cartflags(upper 4-bits (<<8, ignored) + 0000(should be zero)(<<4) + vTsM) 
	DEBUGINFO CARTFLAG, r1

	ldr r0, =IPC_MEMTBL
	ldr_ r1,memmap_tbl+16
	add r1, r1, #0x8000
	str r1, [r0], #4
	ldr_ r1,memmap_tbl+20
	add r1, r1, #0xA000
	str r1, [r0], #4
	ldr_ r1,memmap_tbl+24
	add r1, r1, #0xC000
	str r1, [r0], #4
	ldr_ r1,memmap_tbl+28
	add r1, r1, #0xE000
	str r1, [r0]

	mov r2,#REG_BASE
	strh r2,[r2,#REG_DM0CNT_H]	@DMA stop
	strh r2,[r2,#REG_DM1CNT_H]
	@strh r2,[r2,#REG_DM2CNT_H]
	@strh r2,[r2,#REG_DM3CNT_H]

	ldr_ r0, emuflags
	tst r0, #SOFTRENDER
	bne svbend

	@ldr_ r0,=emuflags
	@ldr r0,[r0]
	ldr_ r0,emuflags
	mov r3, #0					@reset the scale, a fake one...
	tst r0,#NOFLICKER
	bne ev0
		ldr r3,scale			@for flicker scaling
		eor r3,r3,#1
		str r3,scale
ev0:
	@ldr r0,emuflags
	@tst r0,#PALTIMING
	@beq nopal60
	@ldrb r0,PAL60
	@add r0,r0,#1
	@cmp r0,#6
	@movpl r0,#0
	@strb r0,PAL60
nopal60:

	add r1,r2,#REG_BG0CNT		@DMA0 -> BGxCNT + BGxOFS
	str r1,[r2,#REG_DM0DAD]
	tst r3, #1
	ldreq r0,=BGCNTBUFF
	ldrne r0,=BGCNTBUFF+256*16	@for flicker
	ldmia r0!,{r3-r6}
	stmia r1,{r3-r6}			@set 1st values manually, HBL is AFTER 1st line
	str r0,[r2,#REG_DM0SAD]
	ldr r0,=0x96600004			@noIRQ hblank 32bit repeat incsrc inc_reloaddst, 4 word transfer
	str r0,[r2,#REG_DM0CNT_L]		@DMA0 start

	str r2,[r2,#REG_DM1DAD]		@DMA1 -> DISPCNT (BG/OBJ enable)
	ldr r1,=DISPCNTBUFF
	ldr r0,[r1],#4
	str r0,[r2,#REG_DISPCNT]		@set 1st value manually, HBL is AFTER 1st line
	str r1,[r2,#REG_DM1SAD]
	ldr r0,=0x96400001			@noIRQ hblank 16bit repeat incsrc fixeddst, 1 word transfer
	str r0,[r2,#REG_DM1CNT_L]		@DMA1 start
	ldmfd sp!,{r4-r7,globalptr,pc}

svbend:
	ldr_ r0,emuflags
	tst r0,#NOFLICKER
	bne 0f
	
	ldr r1,scale			@for flicker scaling
	eor r1,r1,#1
	str r1,scale
	ldr r2, =0x400003C
	ldrb r3, [r2]
	bic r3, r3, #0xFF
	tst r1, #1
	orrne r3, r3, #0x40
	strb r3, [r2]
0:
	ldmfd sp!,{r4-r7,globalptr,pc}
	.ltorg

scaletable: .skip 256
scaletable2: .skip 256

@---------------------------------------------------------------------------------
ppusync:		@called on NES scanline 0..239 (r0=line)
@---------------------------------------------------------------------------------
	stmfd sp!,{r3,lr}

	ldr_ r0, emuflags
	tst r0, #SOFTRENDER
	bne soft_sync

	tst r0, #LIGHTGUN
	beq 0f
@-------
@lighting gun
	stmfd sp!, {r4-r12}
	bl scanlinestart

	ldr r2,DMAline
	movs r2, r2, lsr#16
	ldr r1, =IPC_TOUCH_Y
	ldrh r1, [r1]
	movmi r1, #0		@undefined area.
	cmp r2, #240
	movcs r1, #239		@over....
	cmp r1, r2

	ldreq_ r0, scanline
	streq_ r0, lighty
	bleq soft_render

	bl scanlinenext
	ldmfd sp!, {r4-r12}

0:
	ldr_ r0, scanline
	adr_ r2,nes_chr_map
	ldr r3,=nes_maps
	add r3, r3, r0, lsl#4
	ldr r1,[r2], #4
	str r1,[r3], #4
	ldr r1,[r2], #4
	str r1,[r3], #4
	ldr r1,[r2], #4
	str r1,[r3], #4
	ldr r1,[r2]
	str r1,[r3]

	bl updateBGCHR		@check for bankswitching
		
	ldr r1,scale
	ldr r2,DMAline
	add r2,r2,r1
	str r2,DMAline
	
	movs r0,r2,asr#16
	movmi r0,#0
	ldr r1, =0x3334
	add r2,r2,r1
	movs r1,r2,asr#16
	movmi r1,#0			@r0,r1=scaled line
	
	@- - - 
	
	ldr r12,=DISPCNTBUFF
	add r12,r12,r0,lsl#2
	ldr r2,dispcnt
	ldr r3,currentBG
	tst r3, #0x80
	orrne r2, r2, #0x04000000
	str r2,[r12]

	@- - -

	ldr r12,=BGCNTBUFF
		add lr,r12,r1,lsl#4
		add lr, lr, #256*16
	add r12,r12,r0,lsl#4
		
	ldr r2,currentBG
	and r2, r2, #0x7F
	ldr_ r3,bg0cnt
	orr r2,r3,r2,lsr#1
	strh r2,[r12]
		strh r2,[r12, #2] @nothing happens
		strh r2,[lr]
		strh r2,[lr, #2]
	
	@- - -
	
	ldr_ r2,scrollX
	strh r2,[r12,#8]
		strh r2,[lr,#8]
		strh r2,[r12,#12]
		strh r2,[lr,#12]
	
	ldr_ r2,scrollY
	sub r3,r2,r0
	strh r3,[r12,#10]
		strh r3,[lr,#14]	@cross the two scrollY table to take ALPHALERP
		sub r3,r2,r1
		strh r3,[lr,#10]
		strh r3,[r12,#14]
	
	add r2,r2,#1
	tst r2,#0xff
	eoreq r2,r2,#0x100	@page wraps with negative scroll
	cmp r2,#0xf0
	cmpne r2,#0x1f0
	addeq r2,r2,#16
	
	str_ r2,scrollY

	@- - -
	ldr_ r0, emuflags
	tst r0, #0x40		@sprite render type
	beq 0f
	stmfd sp!, {r4-r12}
	bl spchr_update
	ldmfd sp!, {r4-r12}
0:
	@- - -
	ldr_ r0, emuflags
	tst r0, #PALSYNC
	beq no_sync

	ldr_ r0, scanline
	ldr_ r1, palsyncline
	cmp r0, r1
	bne no_sync

	cmp r1, #0
	beq no_sync

	cmp r0, #232
	bcs no_sync

	adr r2, scaletable
	ldrb r0, [r2, r0]
	cmp r0, #0
	beq no_sync
	ldr r3, =0x4000006

sync_loop:
	ldrh r1, [r3]
	cmp r1, #192
	bcs sync_loop
	cmp r0, #180
	bcs no_sync
	cmp r1, #180
	bcs no_sync
	cmp r1, r0
	bcc sync_loop
0:

	stmfd sp!, {r0-r8, addy}
	mov r8,#NDS_PALETTE		@palette transfer
	ldr addy,=agb_pal
pal_nf8:
	ldmia addy!,{r0-r7}
	stmia r8,{r0,r1}
	add r8,r8,#32
	stmia r8,{r2,r3}
	add r8,r8,#32
	stmia r8,{r4,r5}
	add r8,r8,#32
	stmia r8,{r6,r7}
	add r8,r8,#0x1a0
	tst r8,#0x200
	bne pal_nf8			@(2nd pass: sprite pal)
	ldmfd sp!, {r0-r8, addy}
no_sync:

	tst r0, #ALLPIXEL
	bne soft_sync

	ldmfd sp!,{r3,pc}
@---
soft_sync:
	ldr_ r0, emuflags
	DEBUGINFO 20, r0

	stmfd sp!, {r4-r12}
	bl scanlinestart

	bl soft_render
	bl scanlinenext
	ldmfd sp!, {r4-r12}
	ldmfd sp!,{r3,pc}

.ltorg

gfx_scale:
scale: .word 0			@bit0=even/odd
DMAline: .word 0
DMAlinestart: .word 0
	
@---------------------------------------------------------------------------------
PPU_R:@
@---------------------------------------------------------------------------------
	and r0,addy,#7
	ldr pc,[pc,r0,lsl#2]
	.word 0
PPU_read_tbl:
	.word empty_PPU_R	@$2000
	.word empty_PPU_R	@$2001
	.word stat_R	@$2002
	.word empty_PPU_R	@$2003
	.word empty_PPU_R	@$2004
	.word empty_PPU_R	@$2005
	.word empty_PPU_R	@$2006
	.word vmdata_R	@$2007
@---------------------------------------------------------------------------------
PPU_W:@
@---------------------------------------------------------------------------------
	and r2,addy,#7
	ldr pc,[pc,r2,lsl#2]
	.word 0
PPU_write_tbl:
	.word ctrl0_W	@$2000
	.word ctrl1_W	@$2001
	.word void	@$2002
	.word void	@$2003
	.word void	@$2004
	.word bgscroll_W	@$2005
	.word vmaddr_W	@$2006
	.word vmdata_W	@$2007
@---------------------------------------------------------------------------------
empty_PPU_R:
@---------------------------------------------------------------------------------
	mov r0,#0
	mov pc,lr
@---------------------------------------------------------------------------------
ctrl0_W:		@(2000)
@---------------------------------------------------------------------------------
	stmfd sp!,{lr}
	
	ldr_ r1, loopy_t
	bic r1, r1, #0xC00
	and r2, r0, #3
	orr r1, r1, r2, lsl#10
	str_ r1, loopy_t

	strb_ r0,ppuctrl0

	mov r1,#1				@+1/+32
	tst r0,#4
	movne r1,#32
	strb_ r1,vramaddrinc

	mov r1,r0,lsr#1
	and r1,r1,#1
	strb_ r1,scrollYtemp+1	@Y scroll

	and r0,r0,#1			@X scroll
	strb_ r0,scrollX+1
	ldmfd sp!,{pc}
@---------------------------------------------------------------------------------
ctrl1_W:		@(2001)
@---------------------------------------------------------------------------------
	strb_ r0,ppuctrl1

	ldr r1,=DISPCNT_INIT

	tst r0,#0x08		@bg en?
	beq cr10

	ldr_ r2,emuflags
	tst r2,#ALPHALERP
	orrne r1,r1,#0x0300
	orreq r1,r1,#0x0100
cr10:
	tst r0,#0x10		@obj en?
	orrne r1,r1,#0x1000

	tst r0,#0x02		@bg clip (obj clip will be forced too, from window oddities)
	orreq r1,r1,#0x2000
	tst r0,#0x04		@obj clip
	orreq r1,r1,#0x4000
		
	str r1,dispcnt
	mov pc,lr
.ltorg

dispcnt: .word DISPCNT_INIT
@---------------------------------------------------------------------------------
stat_R:		@(2002)
@---------------------------------------------------------------------------------
	mov r0,#0
	strb_ r0,toggle
	ldrb_ r2,ppustat
	
	ldr_ r0, emuflags
	tst r0, #SOFTRENDER
	bne 0f

	ldr_ r0,sprite0y			@sprite0 hit?
	ldr_ r1,scanline
	cmp r1,r0
@	ble nosprh
@	ldrb r0,sprite0x			@for extra high resolution sprite0 hit
@	ldr r1,cyclesperscanline	@the store is in IO.s
@	sub r1,r1,cycles
@	cmp r1,r0
	bic r2, #0x40
	orrhi r2,r2,#0x40
@nosprh
0:
	bic r1,r2,#0x80				@vbl flag clear
	strb_ r1,ppustat

	mov r0, r2

	ldrb_ r1, ppuctrl1
	tst r1, #0x10
	biceq r0, #0x60

	mov pc,lr
@---------------------------------------------------------------------------------
bgscroll_W:	@(2005)
@---------------------------------------------------------------------------------
	ldrb_ r1,toggle
	eors r1,r1,#1
	strb_ r1,toggle
	beq bgscrollY
bgscrollX:
	strb_ r0,scrollX
	
	and r1, r0, #7
	str_ r1, loopy_x	@loopy_x = data & 0x07
	str_ r1, loopy_shift
	ldr_ r1, loopy_t
	bic r1, r1, #0x1F
	orr r1, r1, r0, lsr#3
	str_ r1, loopy_t

	mov pc,lr
bgscrollY:
	strb_ r0,scrollYtemp

	ldr_ r1,loopy_t
	bic r1, r1, #0x3E0
	bic r1, r1, #0x7000
	and r2, r0, #7
	orr r1, r1, r2, lsl#12
	and r2, r0, #0xF8
	orr r1, r1, r2, lsl#2
	str_ r1, loopy_t

	ldr_ r1,vramaddr2	@yscroll modifies vramaddrtmp
	bic r1,r1,#0x7300
	bic r1,r1,#0x00e0
	and r2,r0,#0xf8
	and r0,r0,#7
	orr r1,r1,r2,lsl#2
	orr r1,r1,r0,lsl#12
	str_ r1,vramaddr2

	mov pc,lr
@---------------------------------------------------------------------------------
vmaddr_W:	@(2006)
@---------------------------------------------------------------------------------
	ldrb_ r1,toggle
	eors r1,r1,#1
	strb_ r1,toggle
	beq low
high:
	and r0,r0,#0x3f
	strb_ r0,vramaddr2+1
	strb_ r0, loopy_t + 1
	mov pc,lr
low:
	strb_ r0, loopy_t
	ldr_ r1, loopy_t
	str_ r1, loopy_v
	ldr_ r1, loopy_x
	str_ r1, loopy_shift

	strb_ r0,vramaddr2
	ldr_ r1,vramaddr2
	str_ r1,vramaddr

	and r0,r1,#0x7000	@r0=fine Y
	and r2,r1,#0x03e0	@r2=coarse Y
	and addy,r1,#0x0800	@r12=high Y
	mov r0,r0,lsr#12
	orr r0,r0,r2,lsr#2
	orr r0,r0,addy,lsr#3
	str_ r0,scrollY
	str_ r0,scrollYtemp

	ldrb_ r0,scrollX
	and r0,r0,#7		@r0=fine X
	and r2,r1,#0x001f	@r1=coarse X
	and addy,r1,#0x0400	@r2=high X
	orr r0,r0,r2,lsl#3
	orr r0,r0,addy,lsr#2
	str_ r0,scrollX

	mov pc,lr
@---------------------------------------------------------------------------------
vmdata_R:	@(2007)
@---------------------------------------------------------------------------------
	ldr_ r0,vramaddr
	ldrb_ r1,vramaddrinc
	bic r0,r0,#0xfc000
	add r2,r0,r1
	str_ r2,vramaddr

	cmp r0,#0x3f00
	bhs palread

	and r1,r0,#0x3c00
	adr r2,vram_map
	ldr r1,[r2,r1,lsr#8]
	bic r0,r0,#0xfc00

	ldrb r1,[r1,r0]
	ldrb_ r0,readtemp
	str_ r1,readtemp
	mov pc,lr
palread:
	and r0,r0,#0x1f
	adr r1,nes_palette
	ldrb r0,[r1,r0]
	mov pc,lr
@---------------------------------------------------------------------------------
vmdata_W:	@(2007)				@Do not change addy...
@---------------------------------------------------------------------------------
	ldr_ addy,vramaddr
	ldrb_ r1,vramaddrinc
	bic addy,addy,#0xfc000 @AND $3fff
	add r2,addy,r1
	str_ r2,vramaddr

	and r1,addy,#0x3c00
	adr r2,vram_write_tbl
	ldr pc,[r2,r1,lsr#8]
@---------------------------------------------------------------------------------
VRAM_chr:@	0000-1fff
@---------------------------------------------------------------------------------
	ldr r2,=vram_map
	mov r1, addy, lsr#10
	ldr r2, [r2, r1, lsl#2]
	bic r1, addy, #0xFC00
	strb r0,[r2,r1]
					@because some games may switch off/in VRAM(0000-1fff)
	mov pc,lr
@---------------------------------------------------------------------------------
VRAM_name0:	@(2000-23ff)
@---------------------------------------------------------------------------------
	ldr r1,nes_nt0
	ldr r2,agb_nt_map
writeBG:		@loadcart jumps here
	bic addy,addy,#0xfc00	@AND $03ff
	strb r0,[r1,addy]
	cmp addy,#0x3c0
	bhs writeattrib
@writeNT
	add addy,addy,addy	@lsl#1
	ldrh r1,[r2,addy]	@use old color
	and r1,r1,#0xf000
	orr r1,r0,r1
	strh r1,[r2,addy]	@write tile#
	mov pc,lr
writeattrib:
	stmfd sp!,{r3,r4,lr}

	orr r0,r0,r0,lsl#16
	and r1,addy,#0x38
	and addy,addy,#0x07
	add addy,addy,r1,lsl#2
	add addy,r2,addy,lsl#3
	ldr r3,=0x00ff00ff
	ldr r4,=0x00030003

	ldr r1,[addy]
	and r2,r0,r4
	and r1,r1,r3
	orr r1,r1,r2,lsl#12
	str r1,[addy]
		ldr r1,[addy,#0x40]
		and r1,r1,r3
		orr r1,r1,r2,lsl#12
		str r1,[addy,#0x40]
	ldr r1,[addy,#4]
	and r2,r0,r4,lsl#2
	and r1,r1,r3
	orr r1,r1,r2,lsl#10
	str r1,[addy,#4]
		ldr r1,[addy,#0x44]
		and r1,r1,r3
		orr r1,r1,r2,lsl#10
		str r1,[addy,#0x44]
	ldr r1,[addy,#0x80]
	and r2,r0,r4,lsl#4
	and r1,r1,r3
	orr r1,r1,r2,lsl#8
	str r1,[addy,#0x80]
		ldr r1,[addy,#0xc0]
		and r1,r1,r3
		orr r1,r1,r2,lsl#8
		str r1,[addy,#0xc0]
	ldr r1,[addy,#0x84]
	and r2,r0,r4,lsl#6
	and r1,r1,r3
	orr r1,r1,r2,lsl#6
	str r1,[addy,#0x84]
		ldr r1,[addy,#0xc4]
		and r1,r1,r3
		orr r1,r1,r2,lsl#6
		str r1,[addy,#0xc4]
	ldmfd sp!,{r3,r4,lr}
	mov pc, lr
@---------------------------------------------------------------------------------
VRAM_name1:	@(2400-27ff)
@---------------------------------------------------------------------------------
	ldr r1,nes_nt1
	ldr r2,agb_nt_map+4
	b writeBG
@---------------------------------------------------------------------------------
VRAM_name2:	@(2800-2bff)
@---------------------------------------------------------------------------------
	ldr r1,nes_nt2
	ldr r2,agb_nt_map+8
	b writeBG
@---------------------------------------------------------------------------------
VRAM_name3:	@(2c00-2fff)
@---------------------------------------------------------------------------------
	ldr r1,nes_nt3
	ldr r2,agb_nt_map+12
	b writeBG
@---------------------------------------------------------------------------------
VRAM_pal:	@($3F00-$3F1F)
@---------------------------------------------------------------------------------
	cmp addy,#0x3f00
	bmi VRAM_name3

	and r0,r0,#0x3f		@(only colors 0-63 are valid)
	and addy,addy,#0x1f
		tst addy,#0x0f
		moveq addy,#0	@$10 mirror to $00
	adr r1,nes_palette
	orr r2, r0, #128 + 64	@something wrong...
	strb r2,[r1,addy]	@store in nes palette

	tst addy, #3
	bne 0f

	ldrb r2, [r1]
	strb r2, [r1, #4]
	strb r2, [r1, #8]
	strb r2, [r1, #12]
	strb r2, [r1, #16]
	strb r2, [r1, #20]
	strb r2, [r1, #24]
	strb r2, [r1, #28]
0:
	
	add r0,r0,r0
	ldr r1,=MAPPED_RGB
@	ldr r0,[r1,r0,lsl#1]	@lookup RGB, unaligned read.
	ldrh r0,[r1,r0]			@lookup RGB
	adr r1,agb_pal
	add addy,addy,addy	@lsl#1
	strh r0,[r1,addy]	@store in agb palette

	ldr_ r1, scanline
	add r1, r1, #2
	str_ r1, palsyncline
	mov pc, lr
@------------
.ltorg
@---------------------------------------------------------------------------------
newframe:	@called at NES scanline 0	(r0-r9 safe to use)
@---------------------------------------------------------------------------------
	stmfd sp!,{r3-r9,lr}

	ldr_ r0, loopy_t
	str_ r0, loopy_v
	mov r0, r0, lsr#12
	and r0, r0, #7
	str_ r0, loopy_y
	ldr_ r0, loopy_x
	str_ r0, loopy_shift
	ldr_ r0,scrollYtemp
	str_ r0,scrollY

	mov r0, #0
	str_ r0, palsyncline

	ldr_ r0, emuflags
	tst r0, #SOFTRENDER
	bne nfsoft

	ldr_ r0, vrombase
	ldr r1, =NES_VRAM
	cmp r0, r1		@means that the game does NOT have any vrom.
	bne 0f
				@make the guarantee that NDS freshes the 'chr's per frame.
	mov r0,#-1		@code from resetCHR
	adr r1,agb_bg_map
	mov r2,#SLOTS * 2
	bl filler

	mov r0,#-1
	ldr r1,=agb_obj_map
	str r0,[r1],#4
	str r0,[r1],#4
	str r0,[r1],#4
	str r0,[r1],#4

0:
	ldr r0,DMAlinestart	@init scaling stuff
	str r0,DMAline

	ldr_ r0, emuflags
	tst r0, #0x40			@sprite render type
	bleq updateOBJCHR		@(nes_zpage still valid here)
@------------------------
	ldr_ r0, emuflags
	tst r0, #PALSYNC
	beq 1f
	ldr r3, =0x4000006
0:
	ldrb r0, [r3]
	cmp r0, #192
	bcs 0b
1:
	mov r8,#NDS_PALETTE		@palette transfer
	ldr addy,=agb_pal
nf8:	ldmia addy!,{r0-r7}
	stmia r8,{r0,r1}
	add r8,r8,#32
	stmia r8,{r2,r3}
	add r8,r8,#32
	stmia r8,{r4,r5}
	add r8,r8,#32
	stmia r8,{r6,r7}
	add r8,r8,#0x1a0
	tst r8,#0x200
	bne nf8			@(2nd pass: sprite pal)
@-----------------------
nfsoft:
	ldr_ r0,scrollYtemp
	str_ r0,scrollY

	ldmfd sp!,{r3-r9, lr}
	ldr_ pc, newframehook
.ltorg
@---------------------------------------------------------------------------------
agb_pal:		.skip 32*2	@copy this to real AGB palette every frame
nes_palette:	.skip 32	@NES $3F00-$3F1F

vram_write_tbl:	@for vmdata_W, r0=data, addy=vram addr
	.word 0
	.word 0
	.word 0
	.word 0
	.word 0
	.word 0
	.word 0
	.word 0
	.word VRAM_name0	@$2000
	.word VRAM_name1	@$2400
	.word VRAM_name2	@$2800
	.word VRAM_name3	@$2c00
	.word VRAM_name0	@$3000
	.word VRAM_name1	@$3400
	.word VRAM_name2	@$3800
	.word VRAM_pal	@$3c00

vram_map:	@for vmdata_R
	.word 0			@0000
	.word 0			@0400
	.word 0			@0800
	.word 0			@0c00
	.word 0			@1000
	.word 0			@1400
	.word 0			@1800
	.word 0			@1c00
nes_nt0: .word NES_VRAM+0x2000	@2000
nes_nt1: .word NES_VRAM+0x2000	@2400
nes_nt2: .word NES_VRAM+0x2400	@2800
nes_nt3: .word NES_VRAM+0x2400	@2c00
	.word NES_VRAM+0x2C00	@3000
	.word NES_VRAM+0x2C00	@3400
	.word NES_VRAM+0x2C00	@3800
	.word NES_VRAM+0x2C00	@3c00

agb_nt_map:
	.word 0,0,0,0
@---------------------------------------------------------------------------------
BGCNT	= 0x1800
m0000:	.word BGCNT+0x0000,NES_VRAM+0x2000,NES_VRAM+0x2000,NES_VRAM+0x2000,NES_VRAM+0x2000
	.word NDS_BG+0x0000,NDS_BG+0x0000,NDS_BG+0x0000,NDS_BG+0x0000
m1111:	.word BGCNT+0x0100,NES_VRAM+0x2400,NES_VRAM+0x2400,NES_VRAM+0x2400,NES_VRAM+0x2400
	.word NDS_BG+0x0800,NDS_BG+0x0800,NDS_BG+0x0800,NDS_BG+0x0800
m0101:	.word BGCNT+0x4000,NES_VRAM+0x2000,NES_VRAM+0x2400,NES_VRAM+0x2000,NES_VRAM+0x2400
	.word NDS_BG+0x0000,NDS_BG+0x0800,NDS_BG+0x0000,NDS_BG+0x0800
m0011:	.word BGCNT+0x8000,NES_VRAM+0x2000,NES_VRAM+0x2000,NES_VRAM+0x2400,NES_VRAM+0x2400
	.word NDS_BG+0x0000,NDS_BG+0x0000,NDS_BG+0x0800,NDS_BG+0x0800
m0123:	.word BGCNT+0xc000,NES_VRAM+0x2000,NES_VRAM+0x2400,NES_VRAM+0x2800,NES_VRAM+0x2c00
	.word NDS_BG+0x0000,NDS_BG+0x0800,NDS_BG+0x1000,NDS_BG+0x1800
@mapper5 need this
m0000_xram:	.word BGCNT+0x0400,NES_XRAM+0x1C00,NES_XRAM+0x1C00,NES_XRAM+0x1C00,NES_XRAM+0x1C00
	.word NDS_BG+0x2000,NDS_BG+0x2000,NDS_BG+0x2000,NDS_BG+0x2000
@---------------------------------------------------------------------------------
mirror1H_:
	adreq r0,m1111
	adrne r0,m0000
	b mirrorchange
mirrorKonami_:
	movs r1,r0,lsr#2
	tst r0,#1
	bcc mirror2V_
@	bcs mirror1_
mirror1_:
	adrne r0,m1111
	adreq r0,m0000
	b mirrorchange
mirror2V_:
	adreq r0,m0101
	adrne r0,m0011
	b mirrorchange
mirror2H_:
	adreq r0,m0011
	adrne r0,m0101
	b mirrorchange
mirror_xram_0000:
	adr r0,m0000_xram
	b mirrorchange
mirror4_:
	adr r0,m0123
mirrorchange:
	ldrb_ r1,cartflags
	tst r1,#SCREEN4+VS
	ldrne r0,=m0123		@force 4way mirror for SCREEN4 or VS flags

	stmfd sp!,{r3-r5,lr}

		ldmia r0!,{r1}
		str_ r1,bg0cnt
		
		ldr r1,=nes_nt0
		ldmia r0!,{r2-r5}
		stmia r1,{r2-r5}
		
		ldr r1,=agb_nt_map
		ldmia r0!,{r2-r5}
		stmia r1,{r2-r5}
	
	ldmfd sp!,{r3-r5,pc}
.ltorg
@---------------------------------------------------------------------------------
SLOTS		= 16			@slots available for BG CHR cache
.align 8
agb_bg_map:	.skip SLOTS*8	@cached BG groups
agb_obj_map:	.word 0,0,0,0	@cached OBJ groups
currentBG:	.word 0			@BG CHR set in use (*8)
nextBG:		.word 0			@next CHR set to replace
@---------------------------------------------------------------------------------
resetCHR:	@initialize CHR  - used by loadcart
@---------------------------------------------------------------------------------
	stmfd sp!,{lr}

	mov r0,#-1
	adr r1,agb_bg_map
	mov r2,#SLOTS * 2
	bl filler

	mov r0,#-1
	adr r1,agb_obj_map
	str r0,[r1],#4
	str r0,[r1],#4
	str r0,[r1],#4
	str r0,[r1],#4
	
	mov r0,#0
	DEBUGINFO BGMISS,r0
	str r0,currentBG
	str r0,nextBG
	
	mov r0,#0
	strb_ r0,ppuctrl0	@BG gets tileset 0 (ensures first banks get cached first for chr-ram)
	mov r0,#0	
	bl chr01234567_		@default CHR mapping
	bl updateBGCHR
	
	ldmfd sp!,{pc}
@---------------------------------------------------------------------------------
writeCHRTBL: .word chr0_,chr1_,chr2_,chr3_,chr4_,chr5_,chr6_,chr7_

chr0_:
	mov r1,#0
	b chr1k
chr1_:
	mov r1,#1
	b chr1k
chr2_:
	mov r1,#2
	b chr1k
chr3_:
	mov r1,#3
	b chr1k
chr4_:
	mov r1,#4
	b chr1k
chr5_:
	mov r1,#5
	b chr1k
chr6_:
	mov r1,#6
	b chr1k
chr7_:
	mov r1,#7
chr1k:
	ldr_ r2,vrommask
	and r0,r0,r2,lsr#10

	adr_ r2,nes_chr_map
	add r2, r2, r1, lsl#1
	strh r0,[r2]
	
	ldr_ r2,vrombase
	add r0,r2,r0,lsl#10
	ldr r2,=vram_map
	str r0,[r2,r1,lsl#2]
	bx lr
@---------------------------------------------------------------------------------
chr01_:
	mov r1,#0
	b chr2k
chr23_:
	mov r1,#2
	b chr2k
chr45_:
	mov r1,#4
	b chr2k
chr67_:
	mov r1,#6
	@b chr2k
chr2k:
	ldr_ r2,vrommask
	and r0,r0,r2,lsr#11

	mov r0,r0,lsl#1
	adr_ r2,nes_chr_map
	add r2, r2, r1, lsl#1
	strh r0,[r2]
	orr r0,r0,#1
	strh r0,[r2,#2]
	bic r0, r0, #1
	
	ldr_ r2,vrombase
	add r0,r2,r0,lsl#10
	ldr r2,=vram_map
	str r0,[r2,r1,lsl#2]!
	add r0,r0,#0x400
	str r0,[r2,#4]
	bx lr
@---------------------------------------------------------------------------------
chr0123_:
@---------------------------------------------------------------------------------
	ldr_ r2,vrommask
	and r0,r0,r2,lsr#12

	orr r1,r0,r0,lsl#16
	mov r1, r1, lsl#2
	orr r2, r1, #0x00010000
	str_ r2,nes_chr_map
	ldr r2,=0x00030002
	orr r2,r1,r2
	str_ r2,nes_chr_map+4

	ldr_ r1,vrombase
	add r1,r1,r0,lsl#12
	str r1,vram_map
	add r1,r1,#0x400
	str r1,vram_map+4
	add r1,r1,#0x400
	str r1,vram_map+8
	add r1,r1,#0x400
	str r1,vram_map+12
	bx lr
@---------------------------------------------------------------------------------
chr01234567_:
@---------------------------------------------------------------------------------
	ldr_ r2,vrommask
	and r0,r0,r2,lsr#13

	orr r1,r0,r0,lsl#16
	mov r1, r1, lsl#3
	orr r2, r1, #0x00010000
	str_ r2,nes_chr_map
	ldr r2,=0x00030002
	orr r2,r1,r2
	str_ r2,nes_chr_map+4
	ldr r2,=0x00050004
	orr r2,r1,r2
	str_ r2,nes_chr_map+8
	ldr r2,=0x00070006
	orr r2,r1,r2
	str_ r2,nes_chr_map+12

	ldr_ r1,vrombase
	add r1,r1,r0,lsl#13
	str r1,vram_map
	add r1,r1,#0x400
	str r1,vram_map+4
	add r1,r1,#0x400
	str r1,vram_map+8
	add r1,r1,#0x400
	str r1,vram_map+12
	add r1,r1,#0x400
	b _4567
@---------------------------------------------------------------------------------
chr4567_:
@---------------------------------------------------------------------------------
	ldr_ r2,vrommask
	and r0,r0,r2,lsr#12

	orr r1,r0,r0,lsl#16
	mov r1, r1, lsl#2
	orr r2, r1, #0x00010000
	str_ r2,nes_chr_map+8
	ldr r2,=0x00030002
	orr r2,r1,r2
	str_ r2,nes_chr_map+12

	ldr_ r1,vrombase
	add r1,r1,r0,lsl#12
_4567:	str r1,vram_map+16
	add r1,r1,#0x400
	str r1,vram_map+20
	add r1,r1,#0x400
	str r1,vram_map+24
	add r1,r1,#0x400
	str r1,vram_map+28
	bx lr

@---------------------------------------------------------------------------------
updateBGCHR:	@see if BG CHR needs to change, setup BGxCNTBUFF
@---------------------------------------------------------------------------------
	ldrb_ r2,ppuctrl0
	tst r2,#0x10
	stmfd sp!,{r2-r9, lr}
	ldreq_ r0,nes_chr_map
	ldreq_ r8,nes_chr_map+4
	ldrne_ r0,nes_chr_map+8	@r0=new bg chr group
	ldrne_ r8,nes_chr_map+12

	bl bg_chr_req
	ldmfd sp!,{r2-r9, pc}
@---------------------------------------------------------------------------------
updateOBJCHR:	@sprite CHR update (r3-r7 killed)
@---------------------------------------------------------------------------------
	ldrb_ r2,ppuctrl0frame
	tst r2,#0x20	@8x16?
	beq uc3
	mov r12,lr
	bl uc1
	bl uc2
	bx r12
uc3:
	tst r2,#0x08
	bne uc2
uc1:
	ldr_ r0,nes_chr_map
	ldr_ r8,nes_chr_map + 4
	ldr r1,agb_obj_map
	ldr r9,agb_obj_map + 4
	eor r1,r1,r0
	eor r9,r9,r8
	orrs r2, r1, r9
	moveq pc, lr
	str r0,agb_obj_map
	str r8,agb_obj_map + 4
	ldr r5,=NDS_OBJVRAM
	adr r6,agb_obj_map
	b unpack_tiles
uc2:
	ldr_ r0,nes_chr_map+8
	ldr_ r8,nes_chr_map+12
	ldr r1,agb_obj_map+8
	ldr r9,agb_obj_map+12
	eor r9,r9,r8
	eor r1,r1,r0
	orrs r2, r1, r9
	moveq pc,lr
	str r0,agb_obj_map+8
	str r8,agb_obj_map+12
	ldr r5,=NDS_OBJVRAM+0x2000
	adr r6,agb_obj_map+8
	b unpack_tiles
@---------------------------------------------------------------------------------
bg_chr_req:	@request BG CHR group in r0
@		r0=chr group (4 1k CHR pages)
@---------------------------------------------------------------------------------
	adr r6,agb_bg_map

	mov r2,r6
	add r3,r6,#SLOTS*8
bcr0:	ldr r1,[r2],#4
	ldr r4,[r2],#4
	cmp r0, r1
	cmpeq r8, r4
	beq cached
	cmp r2,r3
	bne bcr0
	
	DEBUGCOUNT BGMISS

	ldr r7,nextBG			@r7=group to replace
	ldr r1,[r6,r7]!			@r1=old group
	ldr r9,[r6, #4]
	str r0,[r6]			@save new group, r6=new chr map ptr
	str r8,[r6, #4]
	add r2,r7,#8
	cmp r2,#SLOTS*8
	movcs r2, #0
	str r2,nextBG			@increment nextBG
	eor r1,r1,r0
	eor r9,r9,r8

	
decodeptr	.req r2 @mem_chr_decode
tilecount  .req r3
nesptr		.req r4 @chr src
agbptr		.req r5 @chr dst
bankptr	.req r6 @vrom bank lookup ptr

	mov agbptr,#NDS_VRAM
	add agbptr,agbptr,r7,lsl#11	@0000/4000/8000/...

unpack_tiles:	@r1=old^new, r5=CHR dst, r6=map ---------UPDATEOBJCHR JUMPS HERE

	ldr decodeptr,=CHR_DECODE
bg0:	 movs r0, r1, lsl#16
	 ldrh r0,[bankptr],#2
	 mov r1,r1,lsr#16
	 addeq agbptr,agbptr,#0x800
	 beq bg2
	 mov tilecount,#64
	 ldr_ nesptr,vrombase
	 add nesptr,nesptr,r0,lsl#10	@bank#*$400

bg1:	  ldrb r0,[nesptr],#1
	  ldrb r7,[nesptr,#7]
	  ldr r0,[decodeptr,r0,lsl#2]
	  ldr r7,[decodeptr,r7,lsl#2]
	  orr r0,r0,r7,lsl#1
	  str r0,[agbptr],#4
	  tst agbptr,#0x1f
	  bne bg1
	 subs tilecount,tilecount,#1
	 add nesptr,nesptr,#8
	 bne bg1
bg2:	tst bankptr,#3
	bne bg0

bg0_:	 movs r0, r9, lsl#16
	 ldrh r0,[bankptr],#2
	 mov r9,r9,lsr#16
	 addeq agbptr,agbptr,#0x800
	 beq bg2_
	 mov tilecount,#64
	 ldr_ nesptr,vrombase
	 add nesptr,nesptr,r0,lsl#10	@bank#*$400

bg1_:	  ldrb r0,[nesptr],#1
	  ldrb r7,[nesptr,#7]
	  ldr r0,[decodeptr,r0,lsl#2]
	  ldr r7,[decodeptr,r7,lsl#2]
	  orr r0,r0,r7,lsl#1
	  str r0,[agbptr],#4
	  tst agbptr,#0x1f
	  bne bg1_
	 subs tilecount,tilecount,#1
	 add nesptr,nesptr,#8
	 bne bg1_
bg2_:	tst bankptr,#3
	bne bg0_

	mov pc,lr

cached: @--------------
	sub r2,r2,#8
	sub r7,r2,r6	@r7=group#*8
	str r7,currentBG
	mov pc,lr


@---------------------------------------------------------------------------------
spmask:
	.skip 256 * 4
@--------------------------------------------
spchr_update:
@--------------------------------------------
	@r12 = map_sp
	@r11 = tile_sp
	@r9  = OBJ_sp
	@r8  = i 0~63
	@r7  = spaddr
	@r6  = attr1 | attr2 << 16
	@r5  = ppu_decode
	@r4  = pdatabase

	ldr r9, =NES_SPRAM		@r9 = sp

	ldr_ r3, scanline
	cmp r3, #0
	bne 0f

	mov r2, #240/4
	mov r1, #0
	ldr r0, =spmask
masklp:
	str r1, [r0], #4
	subs r2, r2, #1
	bne masklp

	mov r2, #64
	ldr r5, =0x7000008
	mov r6, #0x200
	mov r3, #0xE0
	str r3, [r5, #-8]
	ldr r0, =spmask

@for sprite0y
	ldrb r1, [r9], #4
	cmp r1, #239
	strcs r6, [r5]
	strcs_ r6, sprite0y
	add r4, r1, #1
	strb r4, [r0, r4]
	add r5, r5, #8

msplp:
	ldrb r1, [r9], #4
	cmp r1, #239
	strcs r6, [r5]
	add r4, r1, #1
	strb r4, [r0, r4]
	add r5, r5, #8
	subs r2, r2, #1
	bne msplp

	mov r1, #0
	str r1, [r0, #239]
	str r1, [r0, #240]

	ldr_ r0, emuflags
	tst r0, #ALLPIXEL
	beq hidesp

	ldr_ r0, pixstart
	cmp r0, #0
	moveq pc, lr

hidesp:
	ldr r3, =NES_SPRAM
	ldr r2, =0x7000008
	mov r4, #0x200
	mov r1, #64

hidesp_loop:
	ldrb r0, [r3], #4
	cmp r0, #239
	strcs r4, [r2]
	add r2, r2, #8
	subs r1, r1, #1
	bne hidesp_loop

	mov pc, lr

0:
	ldr_ r2, pixstart
	cmp r2, #0
	bne 1f

	cmp r3, #239		@r3 = scanline
	bne 1f

	ldr_ r2, emuflags
	tst r2, #ALLPIXEL
	beq 1f

	mov r5, lr
	bl hidesp
	mov lr, r5

1:
	ldrb_ r0, ppuctrl1
	tst r0, #0x10
	moveq pc, lr

	ldr r5, =CHR_DECODE
	ldr_ r3, scanline
	mov r8, #0

	ldr r1, =spmask
	ldr r0, [r1, r3]
	ands r0, r0, r0
	moveq pc, lr

	stmfd sp!, {lr}

splp:
	ldr r12, =0x7000008
	ldrb r0, [r9]
	add r0, r0, #1
	cmp r0, r3
	bne spnext

	ldr r11, =0x6404000

	add r12, r12, r8, lsl#3
	add r11, r11, r8, lsl#6

	cmp r8, #0
	bne 0f			@check sprite0

	stmfd sp!, {r0-r5, r11}
	ldrb_ r3, ppuctrl0
	tst r3, #0x20
	bne sp160
sp80:
	and r0, r3, #0x08
	mov r11, r0, lsl#9
	ldrb r0, [r9, #1]
	add r11, r11, r0, lsl#4	

	mov r0, r11, lsr#10
	bic r1, r11, #0xFC00
	ldr r2, =vram_map
	ldr r2, [r2, r0, lsl#2]

	ldrb r0, [r9]
	ldrb r3, [r2, r1]!
	ldrb r4, [r2, #8]
	orrs r3, r3, r4
	add r0, r0, #1
	bne sp0end

	mov r5, #2
sp0lp:
	ldrb r3, [r2, #1]!
	ldrb r4, [r2, #8]
	orrs r3, r3, r4
	add r0, r0, #1
	bne sp0end
	add r5, r5, #1
	cmp r5, #9
	bne sp0lp
	mov r0, #0x200
	b sp0end

sp160:
	ldrb r0, [r9, #1]
	and r1, r0, #1
	and r2, r0, #0xFE
	mov r11, r1, lsl#12
	add r11, r11, r2, lsl#4		@spraddr = (((INT)sp->tile&1)<<12)+(((INT)sp->tile&0xFE)<<4)

	mov r0, r11, lsr#10
	bic r1, r11, #0xFC00
	ldr r2, =vram_map
	ldr r2, [r2, r0, lsl#2]

	ldrb r0, [r9]
	ldrb r3, [r2, r1]!
	ldrb r4, [r2, #8]
	orrs r3, r3, r4
	add r0, r0, #1
	bne sp0end

	mov r5, #2
sp0lp161:
	ldrb r3, [r2, #1]!
	ldrb r4, [r2, #8]
	orrs r3, r3, r4
	add r0, r0, #1
	bne sp0end
	add r5, r5, #1
	cmp r5, #9
	bne sp0lp161

	add r2, r2, #8
sp0lp162:
	ldrb r3, [r2, #1]!
	ldrb r4, [r2, #8]
	orrs r3, r3, r4
	add r0, r0, #1
	bne sp0end
	add r5, r5, #1
	cmp r5, #17
	bne sp0lp162
	mov r0, #0x200
sp0end:
	@ldrb r1, [r9]
	@cmp r0, r1
	@strne_ r0, sprite0y
	str_ r0, sprite0y
	ldmfd sp!, {r0-r5, r11}
0:

	ldrb r6, [r9, #3]
	ldrb r2, [r9, #2]
	tst r2, #0x80
	orrne r6, r6, #(1 << 13)
	tst r2, #0x40
	orrne r6, r6, #(1 << 12)

	and r1, r2, #3
	orr r6, r6, r1, lsl#(12 + 16)
	orr r6, r6, r8, lsl#17
	orr r6, r6, #0x2000000
	strh r6, [r12, #2]
	mov r1, r6, lsr #16
	strh r1, [r12, #4]

	ldr r1, =scale
	ldr r1, [r1]
	cmp r1, #0xf400 
	ldrcs r4, =spriteY_lookup + 1
	ldrcc r4, =spriteY_lookup
	ldrb r0, [r4, r0]
	tst r2, #0x20
	orrne r0, r0, #(1 << 10)

	ldrb_ r1, ppuctrl0
	tst r1, #0x20
	orrne r0, r0, #0x8000
	strh r0, [r12]			@set cordinate y
	bne sp16
sp8:
	ldrb r0, [r9, #1]
	
	adr lr, 0f
	adr r12, 1f
	ldr_ pc, ppuchrlatch		@r4 returns the new ptr	r1 = ppuctrl0, r0 = tile#
0:	

	and r2, r1, #0x08
	mov r7, r2, lsl#9
	add r7, r7, r0, lsl#4

	mov r0, r7, lsr#10
	bic r1, r7, #0xFC00
	ldr r2, =vram_map
	ldr r4, [r2, r0, lsl#2]
	add r4, r4, r1
1:
	@r6 still available
	tst r6, #(1 << 13)			@v flip.

	mov r1, #0
	ldr r7, =scale
	ldr r7, [r7]
	and r7, r7, #0x1F000
	mov r7, r7, lsr#12
	cmp r7, #14
	addcc r1, r1, #1
	add r2, r11, r1, lsl#2
	mov r0, #0
vclr8:
	cmp r2, r11
	strne r0, [r11], #4
	bne vclr8

2:
	mov r2, #8
	ldr r7, =scale
	ldr r7, [r7]
	and r7, r7, #0x1F000
	ldr r6, =spflick_table8
	ldr r7, [r6, r7, lsr#10]
sp8lp:
	movs r7, r7, lsr #1
	addcc r4, r4, #1
	bcc nohitline8

	ldrb r1, [r4, #8]		@chr_h = PPU_MEM_BANK[spraddr>>10][(spraddr&0x3FF)+8]
	ldrb r0, [r4], #1		@chr_l = PPU_MEM_BANK[spraddr>>10][ spraddr&0x3FF   ]
	ldr r0, [r5, r0, lsl#2]
	ldr r1, [r5, r1, lsl#2]
	orr r0, r0, r1, lsl#1
	str r0, [r11], #4
nohitline8:
	subs r2, #1
	bne sp8lp
	mov r0, #0
clear8:
	tst r11,#0x1f
	strne r0, [r11], #4
	bne clear8
	b spnext

sp16:					@sp16 does NOT have chrlatch.(I think...)
	ldrb r0, [r9, #1]
	and r1, r0, #1
	and r2, r0, #0xFE
	mov r7, r1, lsl#12
	add r7, r7, r2, lsl#4		@spraddr = (((INT)sp->tile&1)<<12)+(((INT)sp->tile&0xFE)<<4)

	mov r0, r7, lsr#10
	bic r1, r7, #0xFC00
	ldr r2, =vram_map
	ldr r4, [r2, r0, lsl#2]
	add r4, r4, r1

	tst r6, #(1 << 13)			@v flip.
	beq 2f

	mov r1, #0
	ldr r7, =scale
	ldr r7, [r7]
	and r7, r7, #0x1F000
	mov r7, r7, lsr#12
	cmp r7, #14
	addcc r1, r1, #2

	add r2, r11, r1, lsl#2
	mov r0, #0
vclr16:
	cmp r2, r11
	strne r0, [r11], #4
	bne vclr16

2:
	@ldrb r0, [r4, r1]!		@chr_l = PPU_MEM_BANK[spraddr>>10][ spraddr&0x3FF   ]
	@ldrb r1, [r4, #8]		@chr_h = PPU_MEM_BANK[spraddr>>10][(spraddr&0x3FF)+8]
	mov r2, #16
	ldr r7, =scale
	ldr r7, [r7]
	and r7, r7, #0x1F000
	ldr r6, =spflick_table16
	ldr r7, [r6, r7, lsr#10]
sp16lp1:
	movs r7, r7, lsr #1
	addcc r4, r4, #1
	bcc nohitline16

	ldrb r1, [r4, #8]
	ldrb r0, [r4],#1
	ldr r0, [r5, r0, lsl#2]
	ldr r1, [r5, r1, lsl#2]
	orr r0, r0, r1, lsl#1
	str r0, [r11], #4
	tst r11, #0x3f
	beq spnext
nohitline16:
	cmp r2, #9
	addeq r4, r4, #8
	subs r2, #1
	bne sp16lp1

	mov r0, #0
clear16:
	tst r11,#0x3f
	strne r0, [r11], #4
	bne clear16

spnext:
	add r8, r8, #1
	cmp r8, #64
	addne r9, r9, #4
	bne splp

	ldmfd sp!, {pc}

spflick_table8:
	.word 0,0,0,0,0,0,0,0,0,0,0		@these values mean nothing.
	.word 0x7B
	.word 0xFB
	.word 0xFB
	.word 0xFF
	.word 0xFF
	.word 0xFF
spflick_table16:
	.word 0,0,0,0,0,0,0,0,0,0,0		@these values mean nothing.
	.word 0xDE7B
	.word 0xDFFB
	.word 0xDFFB
	.word 0xFFFF
	.word 0xFFFF
	.word 0xFFFF

@---------------------------------------------------------------------------------
vromnt1k:	@r1=nt0...3
@---------------------------------------------------------------------------------
	adr r2, bank_cache
	add r2, r2, r1, lsl#1		@two bytes...
	ldrh r2, [r2]
	cmp r0, r2
	moveq pc, lr

	stmfd sp!, {r3-r9, lr}

	adr r2, bank_cache
	add r2, r2, r1, lsl#1
	strh r0, [r2]

	ldr_ r3, vrombase
	ldr r2, =NDS_BG + 0x2000		@point to a free Map area.
	add r2, r2, r1, lsl#11
	add r4, r3, r0, lsl#10

	add r6, r4, #0x3C0			@the tile attr base.
	adr r7, ntdata
	mov r9, #8*8

nt_loop:
	ldrb r8, [r6], #1
	and r0, r8, #3
	strb r0, [r7]
	mov r8, r8, lsr#2
	and r0, r8, #3
	strb r0, [r7, #1]
	mov r8, r8, lsr#2
	and r0, r8, #3
	strb r0, [r7, #16]
	mov r8, r8, lsr#2
	strb r8, [r7, #17]

	subs r9, r9, #1
	beq 0f
	tst r9, #7				@one row will be 8 bytes
	addne r7, r7, #2
	addeq r7, r7, #18
	b nt_loop
	
0:
	mov r6, #0
	adr r7, ntdata

tilenum_loop:
	mov r1, r6, lsr#6
	and r0, r6, #0x1e
	mov r0, r0, lsr#1
	add r0, r0, r1, lsl#4

	ldrb r1, [r7, r0]
	and r1, r1, #3
	ldrb r0, [r4], #1
	orr r0, r0, r1, lsl#12
	strh r0, [r2], #2
	add r6, r6, #1
	cmp r6, #32*30
	bcc tilenum_loop

	ldmfd sp!, {r3-r9, pc}

@---------------------------------------------------------------------------------
bank_cache:
	.skip 8
ntdata:
	.skip 8*8*2*2

@---------------------------------------------------------------------------------
.section .dtcm,"aw"
@---------------------------------------------------------------------------------
obj_tileset:
	.skip 240
@---------------------------------------------------------------------------------
nes_maps:	.skip 240*16
