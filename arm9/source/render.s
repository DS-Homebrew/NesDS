#include "equates.h"
#include "6502mac.h"
	.global soft_render
	.global dmaCopy_s
	.global nes_palette
	.global render_fun
	.global bg_render_bottom
	.global render_all
	.global render_sub
	.global renderdata
	.global renderbgdata
	.global scanlinenext
	.global scanlinestart
	.global rev_data
	
	@for crash check
	.global normal_sp
	.global dummy_render
	.global dummy_lp
	.global dummy_nt
	.global sp_render
	.global sp_lp
	.global sp8
	.global sp16
	.global sp16v
	.global show_sp
	.global sp_noh
	.global hitend
	.global hitcheck
	.global sp_mask
	.global sp_attr
	.global sp_next
	.global sp_end
	.global bg_normal
	.global bglp
	.global bgnocache
	.global bgnext
	.global bgnext1
	.global bg_render
	.global BGwrite_data	
	.global SPwrite_data	
	.global rev_data	
@renderdata = 0x6040000 - 4

tileofs 	= tempdata
ntbladr 	= tileofs + 4
attradr 	= ntbladr + 4
ntbl_x  	= attradr + 4
attrsft 	= ntbl_x + 4
pNTBL 		= attrsft + 4
pScn		= pNTBL + 4
pBGw		= pScn + 4
attr		= pBGw + 4
BGwrite		= attr + 4
SPwrite		= BGwrite + 4
Bit2Rev		= SPwrite + 4

.section .itcm, "ax"
@---------------------------------------------------------------------------------
scanlinestart:
@---------------------------------------------------------------------------------
	ldrb_ r0, ppuctrl1
	tst r0, #0x18			@tst (bgdisp | spdisp)
	moveq pc, lr
	ldr_ r2, loopy_v
	ldr_ r1, loopy_t
	ldr r0, =0xFBE0
	and r2, r2, r0
	ldr r0, =0x41F
	and r1, r1, r0
	orr r2, r2, r1			@loopy_v = (loopy_v & 0xFBE0)|(loopy_t & 0x041F)
	str_ r2, loopy_v
	and r2, r2, #0x7000
	mov r2, r2, lsr#12
	str_ r2, loopy_y		@loopy_y = (loopy_v&0x7000)>>12
	ldr_ r0, loopy_x
	str_ r0, loopy_shift		@loopy_shift = loopy_x
	mov pc, lr

@---------------------------------------------------------------------------------
scanlinenext:
@---------------------------------------------------------------------------------
	ldrb_ r0, ppuctrl1
	tst r0, #0x18			@tst (bgdisp | spdisp)
	moveq pc, lr

	ldr_ r2, loopy_v
	and r1, r2, #0x7000
	cmp r1, #0x7000
	bne lpv2
	bic r2, r2, #0x7000
	and r1, r2, #0x3E0
	cmp r1, #0x3A0
	bne lpv1
	eor r2, r2, #0x800
	bic r2, r2, #0x3E0
	b lpvend
lpv1:
	cmp r1, #0x3E0
	addne r2, r2, #0x20
	biceq r2, r2, #0x3E0
	b lpvend
lpv2:
	add r2, r2, #0x1000
lpvend:
	mov r1, r2, lsr#12
	and r1, r1, #7
	str_ r1, loopy_y
	str_ r2, loopy_v
	mov pc, lr

@--------------------------------------------
soft_render:
@r0 for scanline r1=free
@--------------------------------------------
	ldr_ r1, emuflags
	tst r1, #SOFTRENDER
	bne soft_r

	tst r1, #ALLPIXEL
	beq soft_r
@for allpixel

	ldr_ r0, scanline
	ldr_ r1, pixstart
	cmp r0, r1
	movcc pc, lr
	ldr_ r1, pixend
	cmp r0, r1
	movhi pc, lr
	bne normal_sp
@wait for vbl sync:
	ldr_ r0, emuflags
	tst r0, #FASTFORWARD
	movne pc, lr

	ldr_ r0, pixstart
	cmp r0, #0
	movne pc, lr

	stmfd sp!, {r3-r4, lr}
	bl swiWaitForVBlank
	ldmfd sp!, {r3-r4, pc}

soft_r:
	ldrb_ r1, rendercount
	cmp r1, #0
	bne dummy_render
	ldrb_ r0, scanline/*
	cmp r0, #8
	bcc dummy_render
	cmp r0, #232
	bcs dummy_render*/

normal_sp:
	stmfd sp!,{lr}
	
	ldr r1, =BGwrite_data
	mov r0, #0x0
	mov r2, #36/4 * 2
	bl filler
	
	ldr_ r0, scanline
	bl bg_render

	ldrb_ r0, ppustat		@PPUREG[2] &= ~PPU_SPMAX_FLAG;
	bic r0, #0x20
	strb_ r0, ppustat

	ldrb_ r0, ppuctrl1
	tst r0, #0x10
	ldr_ r0, scanline
	blne sp_render
	ldmfd sp!,{pc}

@--------------------------------------------
dummy_render:
@--------------------------------------------
	ldrb_ r0, ppustat
	bic r0, #0x20
	strb_ r0, ppustat
	
	ldrb_ r0, ppuctrl1
	tst r0, #0x10
	moveq pc, lr
	
	ldrb_ r1, ppuctrl0
	tst r1, #0x20
	movne r2, #15
	moveq r2, #7
	
	stmfd sp!, {r3-r6}
	mov r3, #0
	mov r6, #0
	ldr r4, =NES_SPRAM
	ldrb_ r5, scanline
	sub r5, r5, #1
	
dummy_lp:
	ldrb r0, [r4], #4
	sub r0, r5, r0
	and r1, r0, r2
	cmp r0, r1
	bne dummy_nt
	
	cmp r3, #0
	ldreqb_ r1, ppustat
	orreq r1, r1, #0x40
	streqb_ r1, ppustat

	add r6, r6, #1
	cmp r6, #8
	bne dummy_nt
	ldrb_ r0, ppustat
	orr r0, #0x20
	strb_ r0, ppustat
	
	ldmfd sp!, {r3-r6}
	mov pc, lr

dummy_nt:
	add r3, r3, #1
	cmp r3, #64
	bne dummy_lp

	ldmfd sp!, {r3-r6}
	mov pc, lr
@--------------------------------------------
sp_render:
@r0 = linenumber
@--------------------------------------------
	stmfd sp!,{r2-r9, cpu_zpage, addy, lr}
	ldr r1, =renderdata
	add r1, r1, r0, lsl#8		@r1 = renderdata
	str_ r1, pScn		@store pScn
	
	mov r12, #0			@spmax = 0
					@r11 = spraddr, r9 = sp_y, r8 = sp_h, r7 = chr_h, r6 = chr_l, r5 = sp, r4 = i
	ldr r5, =NES_SPRAM		@r5 = sp
	ldrb_ r1, ppuctrl0
	tst r1, #0x20
	movne r8, #15			@r8 = sp_h = (PPUREG[0]&PPU_SP16_BIT)?15:7
	moveq r8, #7
	
	mov r4, #0
	
sp_lp:
	ldr_ r0, scanline
	ldrb r1, [r5]
	sub r9, r0, r1
	subs r9, r9, #1			@sp_y = scanline - (sp->y+1)
	bcc sp_next
	cmp r9, r8
	bhi sp_next
	
	ldrb_ r3, ppuctrl0
	tst r3, #0x20			@ PPUREG[0]&PPU_SP16_BIT
	bne sp16
sp8:
	and r0, r3, #0x08
	mov r11, r0, lsl#9
	ldrb r0, [r5, #1]
	add r11, r11, r0, lsl#4		@spraddr = (((INT)PPUREG[0]&PPU_SPTBL_BIT)<<9)+((INT)sp->tile<<4)
	
	ldrb r0, [r5, #2]
	tst r0, #0x80
	addeq r11, r11, r9
	addne r11, r11, #7
	subne r11, r11, r9
	b show_sp
sp16:
	ldrb r0, [r5, #1]
	and r1, r0, #1
	and r2, r0, #0xFE
	mov r11, r1, lsl#12
	add r11, r11, r2, lsl#4		@spraddr = (((INT)sp->tile&1)<<12)+(((INT)sp->tile&0xFE)<<4)
	
	ldrb r0, [r5, #2]
	tst r0, #0x80
	bne sp16v
	
	and r0, r9, #8
	and r1, r9, #7
	add r11, r11, r1
	add r11, r11, r0, lsl#1
	b show_sp

sp16v:
	and r0, r9, #8
	and r1, r9, #7
	tst r0, #8
	addeq r11, r11, #0x10
	add r11, r11, #7
	sub r11, r11, r1

show_sp:
	mov r0, r11, lsr#10
	bic r1, r11, #0xFC00
	ldr r2, =vram_map
	ldr r2, [r2, r0, lsl#2]
	ldrb r6, [r2, r1]!		@chr_l = PPU_MEM_BANK[spraddr>>10][ spraddr&0x3FF   ]
	ldrb r7, [r2, #8]		@chr_h = PPU_MEM_BANK[spraddr>>10][(spraddr&0x3FF)+8]

	mov r0, r11
	adr lr, 0f
	ldr_ pc, ppuchrlatch
0:	
	ldrb r0, [r5, #2]
	tst r0, #0x40
	beq sp_noh

	ldr_ r1, Bit2Rev
	ldrb r6, [r1, r6]
	ldrb r7, [r1, r7]
	
sp_noh:
	orr r11, r6, r7			@SPpat = chr_l|chr_h
	cmp r4, #0
	bne sp_mask
	ldrb_ r3, ppustat
	tst r3, #0x40
	bne sp_mask
hitcheck:
	ldrb r0, [r5, #3]		@r0 = sp->x
	stmfd sp!, {r6-r7}
	ldr_ r1, loopy_shift		@r1 = loopy_shift
	add r2, r0, r1
	mov r6, r2, lsr#3		@r6 = BGpos = ((sp->x&0xF8)+((loopy_shift+(sp->x&7))&8))>>3
	and r2, r2, #7
	rsb r7, r2, #8			@r7 = BGsft = 8-((loopy_shift+sp->x)&7)
	
	ldr_ r2, BGwrite
	ldrb r0, [r2, r6]!
	ldrb r1, [r2, #1]
	orr r2, r1, r0, lsl#8
	mov r0, r2, lsr r7		@r0 = BGmsk = (((WORD)pBGw[BGpos+0]<<8)|(WORD)pBGw[BGpos+1])>>BGsft
					@still r3 = ppustat
	ands r0, r0, r11
	beq hitend
	
	orr r3, r3, #0x40
	strb_ r3, ppustat
hitend:
	ldmfd sp!, {r6, r7}

sp_mask:
	stmfd sp!, {r6-r9}
	ldrb r0, [r5, #3]		@r0 = sp->x
	mov r6, r0, lsr#3		@r6 = SPpos = sp->x/8
	and r1, r0, #7
	rsb r7, r1, #8			@r7 = SPsft = 8-(sp->x&7)
	ldr_ r2, SPwrite
	ldrb r0, [r2, r6]!
	ldrb r1, [r2, #1]
	orr r3, r1, r0, lsl#8
	mvn r8, r3, lsr r7		@(~r8) = SPmsk = (((WORD)pSPw[SPpos+0]<<8)|(WORD)pSPw[SPpos+1])>>SPsft
	mov r9, r11, lsl r7		@r9 = SPwrt = (WORD)SPpat<<SPsft
	mov r3, r9, lsr#8
	orr r0, r0, r3
	ldr_ r2, SPwrite
	strb r0, [r2, r6]!		@pSPw[SPpos+0] |= SPwrt >> 8
	and r3, r9, #0xFF
	orr r1, r1, r3
	strb r1, [r2, #1]		@pSPw[SPpos+1] |= SPwrt & 0xFF
	
	and r11, r11, r8		@SPpat &= ~SPmsk
	
	ldmfd sp!, {r6-r9}
	
	ldrb r3, [r5, #2]
	tst r3, #0x20
	beq sp_attr

@BG > SP priority	
	ldrb r0, [r5, #3]		@r0 = sp->x
	stmfd sp!, {r6-r7}
	ldr_ r1, loopy_shift		@r1 = loopy_shift
	add r2, r0, r1
	mov r6, r2, lsr#3		@r6 = BGpos = ((sp->x&0xF8)+((loopy_shift+(sp->x&7))&8))>>3
	and r2, r2, #7
	rsb r7, r2, #8			@r7 = BGsft = 8-((loopy_shift+sp->x)&7)
	
	ldr_ r2, BGwrite
	ldrb r0, [r2, r6]!
	ldrb r1, [r2, #1]
	orr r2, r1, r0, lsl#8
	mvn r0, r2, lsr r7		@~r0 = BGmsk = (((WORD)pBGw[BGpos+0]<<8)|(WORD)pBGw[BGpos+1])>>BGsft
	
	and r11, r11, r0
	ldmfd sp!, {r6, r7}
	
sp_attr:
	stmfd sp!, {r4, r8-r9}
	ldrb r3, [r5, #2]
	and r0, r3, #3
	ldr r1, =nes_palette + 16
	add r8, r1, r0, lsl#2		@r8 = pSPPAL = &SPPAL[(sp->attr&SP_COLOR_BIT)<<2]
	ldrb r0, [r5, #3]
	ldr_ r1, pScn
	@add r2, r0, #8
	add r2, r0, #0
	add r9, r2, r1			@r9 = pScn = lpScanline+sp->x+8
	
	and r0, r6, #0xAA
	and r1, r7, #0xAA
	orr r3, r1, r0, lsr#1		@r3 = c1 = ((chr_l>>1)&0x55)|(chr_h&0xAA)
	and r0, r6, #0x55
	and r2, r7, #0x55
	orr r4, r0, r2, lsl#1		@r4 = c2 = (chr_l&0x55)|((chr_h<<1)&0xAA)
	
	tst r11, #0x80
	ldrneb r0, [r8, r3, lsr#6]	@r0 = pSPPAL[(c1>>6)]
	strneb r0, [r9]			@pScn[0] = pSPPAL[(c1>>6)]
	tst r11, #0x40
	ldrneb r0, [r8, r4, lsr#6]	@r0 = pSPPAL[(c2>>6)]
	strneb r0, [r9, #1]		@pScn[1] = pSPPAL[(c2>>6)]
	bic r3, r3, #0xC0		@clear bit6 bit7
	bic r4, r4, #0xC0
	
		tst r11, #0x20
		ldrneb r0, [r8, r3, lsr#4]	@r0 = pSPPAL[(c1>>4)&3]
		strneb r0, [r9, #2]			@pScn[2] = pSPPAL[(c1>>4)&3]
		tst r11, #0x10
		ldrneb r0, [r8, r4, lsr#4]	@r0 = pSPPAL[(c2>>4)&3]
		strneb r0, [r9, #3]		@pScn[3] = pSPPAL[(c2>>4)&3]
		bic r3, r3, #0x30		@clear bit4 bit5
		bic r4, r4, #0x30
	
		tst r11, #0x8
		ldrneb r0, [r8, r3, lsr#2]	@r0 = pSPPAL[(c1>>2)&3]
		strneb r0, [r9, #4]			@pScn[4] = pSPPAL[(c1>>2)&3]
		tst r11, #0x4
		ldrneb r0, [r8, r4, lsr#2]	@r0 = pBGPAL[(c2>>2)&3]
		strneb r0, [r9, #5]		@pScn[5] = pSPPAL[(c2>>2)&3]
		bic r3, r3, #0xC		@clear bit3 bit2
		bic r4, r4, #0xC
	
		tst r11, #0x2
		ldrneb r0, [r8, r3]		@r0 = pBGPAL[c1&3]
		strneb r0, [r9, #6]			@pScn[6] = pBGPAL[c1&3]
		tst r11, #0x1
		ldrneb r0, [r8, r4]		@r0 = pBGPAL[c2&3]
		strneb r0, [r9, #7]		@pScn[7] = pBGPAL[c2&3]
	
	ldmfd sp!, {r4, r8-r9}
	add r12, r12, #1
	cmp r12, #8
	ldreqb_ r0, ppustat
	orreq r0, r0, #0x20
	streqb_ r0, ppustat
	beq sp_end

sp_next:
	add r4, r4, #1
	add r5, r5, #4
	cmp r4, #64
	bne sp_lp
	
sp_end:
	ldmfd sp!,{r2-r9, cpu_zpage, addy, pc}

@--------------------------------------------
bg_render:
@r0 = linenumber r1 is free
@--------------------------------------------
	ldrb_ r1, ppuctrl1
	tst r1, #0x8
	bne bg_normal
	
	ldr r1, =renderdata
	add r1, r1, r0, lsl#8
	ldr r0, =nes_palette
	ldrb r0, [r0]
	orr r0, r0, r0, lsl#8
	orr r0, r0, r0, lsl#16
	mov r2, #256/4
	b filler

	mov pc, lr

	
bg_normal:
	stmfd sp!,{r2-r12, r14} @r2-r9, r10, r11, r12, r14
	@Without Extension Latch
		
	ldr r1, =renderdata
	add r1, r1, r0, lsl#8		@r1 = renderdata
	ldr_ r2, loopy_shift		@r2 = loopy_shift
	@rsb r2, r2, #8
	sub r1, r1, r2			@r1 = pScn = lpScanline+(8-loopy_shift)
	str_ r1, pScn			@store pScn
	
	ldrb_ r1, ppuctrl0
	and r1, r1, #0x10
	mov r1, r1, lsl#8		@r1 = tileofs
	str_ r1, tileofs		@store tileofs
	
	ldr_ r5, loopy_v		@r3 = loopy_v
	bic r2, r5, #0xF000		@r2 = loopy_v&0x0FFF
	add r1, r2, #0x2000		@r1 = ntbladr
	str_ r1, ntbladr		@store ntbladr
	
	and r2, r1, #0x001F		@r2 = ntbl_x  = ntbladr&0x001F
	and r3, r1, #0x40		
	mov r3, r3, lsr#4		@r3 = attrsft = (ntbladr&0x0040)>>4
	str_ r2, ntbl_x			@store ntbl_x
	str_ r3, attrsft		@store attrsft
	
	mov r3, r1, lsr#10
	ldr r2, =vram_map
	ldr r3, [r2, r3, lsl#2]		@r3 = pNTBL = PPU_MEM_BANK[ntbladr>>10]
	str_ r3, pNTBL
	
	and r2, r5, #0xC00
	and r4, r5, #0x380
	add r1, r2, r4, lsr#4
	add r1, r1, #0x2300
	add r1, r1, #0xC0		@r1 = attradr = 0x23C0+(loopy_v&0x0C00)+((loopy_v&0x0380)>>4)
	bic r1, r1, #0xFC00		@r1 = attradr &= 0x3FF
	str_ r1, attradr
	
	mov r12, #0xFF			@not fixed, r12 = cache_attr
	add r11, r12, #0xFF00		@not fixed, r11 = cache_tile
	mov r11, r11, lsl#16
					@fixed, r9 = tileadr
	mov r8, #0			@fixed, r8 = 0 ~ 32
	ldr_ r7, pNTBL			@fixed, r7 = pNTBL
	ldr_ r6, attr			@fixed, r6 = attr
	ldr_ r5, ntbladr		@fixed, r5 = ntbladr
	ldr_ r4, ntbl_x			@fixed, r4 = ntbl_x
	ldr_ r3, attradr		@fixed, r3 = attradr
					
					@not fixed, r3 = chr_h
					@not fixed, r2 = chr_l
bglp:
					@tileadr = tileofs+pNTBL[ntbladr&0x03FF]*0x10+loopy_y
	ldr_ r0, tileofs
	bic r1, r5, #0xFC00
	ldr_ r2, loopy_y
	ldrb r1, [r7, r1]
	add r9, r0, r2
	add r9, r9, r1, lsl#4		@r9 = tileadr, as shown before
	
					@attr = ((pNTBL[attradr+(ntbl_x>>2)]>>((ntbl_x&2)+attrsft))&3)<<2;
	add r0, r3, r4, lsr#2
	ldrb r0, [r7, r0]
	and r1, r4, #2
	ldr_ r2, attrsft
	add r1, r1, r2
	mov r0, r0, lsr r1
	and r0, r0, #3
	mov r6, r0, lsl#2
	
	cmp r11, r9
	cmpeq r12, r6
	cmpeq r8, #0
	bne bgnocache
	
	
	ldr_ r0, pScn
	sub r2, r0, #8
	ldrb r1, [r2], #1		@*(LPDWORD)(pScn+0) = *(LPDWORD)(pScn-8)
	strb r1, [r0], #1		@*(LPDWORD)(pScn+4) = *(LPDWORD)(pScn-4)
		ldrb r1, [r2], #1
		strb r1, [r0], #1
		ldrb r1, [r2], #1
		strb r1, [r0], #1
		ldrb r1, [r2], #1
		strb r1, [r0], #1
		ldrb r1, [r2], #1
		strb r1, [r0], #1
		ldrb r1, [r2], #1
		strb r1, [r0], #1
		ldrb r1, [r2], #1
		strb r1, [r0], #1
		ldrb r1, [r2], #1
		strb r1, [r0], #1
	ldr_ r2, BGwrite		@*(pBGw+0) = *(pBGw-1)
	add r0, r2, r8
	ldrb r1, [r0, #-1]
	strb r1, [r0]
	b bgnext

bgnocache:
	mov r11, r9			@cache_tile = tileadr
	mov r12, r6			@cache_attr = attr
	stmfd sp!, {r3 - r5, r11 - r12}	@no enough register
	mov r0, r9, lsr#10
	bic r1, r9, #0xFC00
	ldr r2, =vram_map
	ldr r0, [r2, r0, lsl#2]
	ldrb r11, [r0, r1]!		@r11 = chr_l
	ldrb r12, [r0, #8]		@r12 = chr_h
	
	orr r0, r11, r12		@*pBGw = chr_h|chr_l
	ldr_ r1, BGwrite
	strb r0, [r1, r8]
	
	ldr r5, =nes_palette
	add r5, r5, r6			@r5 = pBGPAL
	and r0, r11, #0xAA
	and r1, r12, #0xAA
	orr r3, r1, r0, lsr#1		@r3 = c1 = ((chr_l>>1)&0x55)|(chr_h&0xAA)
	and r0, r11, #0x55
	and r2, r12, #0x55
	orr r4, r0, r2, lsl#1		@r4 = c2 = (chr_l&0x55)|((chr_h<<1)&0xAA)
	
	ldr_ r2, pScn			@r2 = pScn
	
	cmp r8, #0
	bne 0f				@normal

	ldrb_ r11, loopy_shift
	cmp r11, #1

	ldrccb r0, [r5, r3, lsr#6]	@r0 = pBGPAL[(c1>>6)]
	strccb r0, [r2]			@pScn[0] = pBGPAL[(c1>>6)]
	cmp r11, #2
	ldrccb r0, [r5, r4, lsr#6]	@r0 = pBGPAL[(c2>>6)]
	strccb r0, [r2, #1]		@pScn[1] = pBGPAL[(c2>>6)];
	bic r3, r3, #0xC0		@clear bit6 bit7
	bic r4, r4, #0xC0
	
		cmp r11, #3
		ldrccb r0, [r5, r3, lsr#4]	@r0 = pBGPAL[(c1>>4)&3]
		strccb r0, [r2, #2]		@pScn[2] = pBGPAL[(c1>>4)&3]
		cmp r11, #4
		ldrccb r0, [r5, r4, lsr#4]	@r0 = pBGPAL[(c2>>4)&3]
		strccb r0, [r2, #3]		@pScn[3] = pBGPAL[(c2>>4)&3];
		bic r3, r3, #0x30		@clear bit4 bit5
		bic r4, r4, #0x30
	
		cmp r11, #5
		ldrccb r0, [r5, r3, lsr#2]	@r0 = pBGPAL[(c1>>2)&3]
		strccb r0, [r2, #4]		@pScn[4] = pBGPAL[(c1>>2)&3]
		cmp r11, #6
		ldrccb r0, [r5, r4, lsr#2]	@r0 = pBGPAL[(c2>>2)&3]
		strccb r0, [r2, #5]		@pScn[5] = pBGPAL[(c2>>2)&3];
		bic r3, r3, #0xC		@clear bit2 bit3
		bic r4, r4, #0xC
	
		cmp r11, #7
		ldrccb r0, [r5, r3]		@r0 = pBGPAL[c1&3]
		strccb r0, [r2, #6]		@pScn[6] = pBGPAL[c1&3]
		ldrb r0, [r5, r4]		@r0 = pBGPAL[c2&3]
		strb r0, [r2, #7]		@pScn[7] = pBGPAL[c2&3];
	
	ldmfd sp!, {r3 - r5, r11 - r12}
	b bgnext
0:
	ldrb r0, [r5, r3, lsr#6]	@r0 = pBGPAL[(c1>>6)]
	strb r0, [r2]			@pScn[0] = pBGPAL[(c1>>6)]
	ldrb r0, [r5, r4, lsr#6]	@r0 = pBGPAL[(c2>>6)]
	strb r0, [r2, #1]		@pScn[1] = pBGPAL[(c2>>6)];
	bic r3, r3, #0xC0		@clear bit6 bit7
	bic r4, r4, #0xC0
	
		ldrb r0, [r5, r3, lsr#4]	@r0 = pBGPAL[(c1>>4)&3]
		strb r0, [r2, #2]		@pScn[2] = pBGPAL[(c1>>4)&3]
		ldrb r0, [r5, r4, lsr#4]	@r0 = pBGPAL[(c2>>4)&3]
		strb r0, [r2, #3]		@pScn[3] = pBGPAL[(c2>>4)&3];
		bic r3, r3, #0x30		@clear bit4 bit5
		bic r4, r4, #0x30
	
		ldrb r0, [r5, r3, lsr#2]	@r0 = pBGPAL[(c1>>2)&3]
		strb r0, [r2, #4]		@pScn[4] = pBGPAL[(c1>>2)&3]
		ldrb r0, [r5, r4, lsr#2]	@r0 = pBGPAL[(c2>>2)&3]
		strb r0, [r2, #5]		@pScn[5] = pBGPAL[(c2>>2)&3];
		bic r3, r3, #0xC		@clear bit2 bit3
		bic r4, r4, #0xC
	
		ldrb r0, [r5, r3]		@r0 = pBGPAL[c1&3]
		strb r0, [r2, #6]		@pScn[6] = pBGPAL[c1&3]
		ldrb r0, [r5, r4]		@r0 = pBGPAL[c2&3]
		strb r0, [r2, #7]		@pScn[7] = pBGPAL[c2&3];
	
	ldmfd sp!, {r3 - r5, r11 - r12}

bgnext:
	ldr_ r0, pScn
	add r0, r0, #8
	str_ r0, pScn			@pScn+=8;

	mov r0, r9
	adr lr, 0f
	ldr_ pc, ppuchrlatch
0:
	add r4, r4, #1			@ntbl_x += 1
	cmp r4, #32
	addne r5, r5, #1		@ntbladr++
	bne bgnext1

	mov r4, #0
	eor r5, r5, #0x1F
	eor r5, r5, #0x400		@ntbladr ^= 0x41F
	and r2, r5, #0x380
	mov r2, r2, lsr#4
	add r3, r2, #0x3C0		@attradr = 0x03C0+((ntbladr&0x0380)>>4)
	mov r2, r5, lsr#10
	ldr r0, =vram_map
	ldr r7, [r0, r2, lsl#2]		@pNTBL = PPU_MEM_BANK[ntbladr>>10]
	
bgnext1:
	add r8, r8, #1
	cmp r8, #33
	bne bglp

	ldmfd sp!,{r2-r12, pc}

@--------------------------------------------
bg_render_bottom:
@--------------------------------------------
	stmfd sp!,{r0-r2, lr}
	ldr r1,=renderbgdata
	ldr r2,=nes_palette
	ldrb r2, [r2]		@get bg color #0
	orr r2, r2, r2, lsl#8
	orr r2, r2, r2, lsl#16
	
	str r2,[r1]
	ldr r0, =renderdata
	bl dma_async_fix
	ldmfd sp!,{r0-r2, pc}
@------------
	mov r0, #256*240/4
bg_btm:
	str r1, [r2], #4
	subs r0, r0, #1
	bne bg_btm
	ldmfd sp!,{r0-r2}
	mov pc,lr

@--------------------------------------------
bg_render_reset:
@--------------------------------------------
	stmfd sp!,{r0-r1, lr}
	ldr r0, =renderdata
	ldr r1, =renderbgdata
	@mov r2, #256
	bl dma_async
	ldmfd sp!, {r0-r1, pc}

@--------------------------------------------
render_transfer:
@--------------------------------------------
	stmfd sp!,{r0-r2, lr}
	ldr r2, =0x6040000
	add r0, r2, r0, lsl#8
	ldr r1, =renderdata
	bl dma_async
	ldmfd sp!, {r0-r2, pc}
	
@--------------------------------------------
render_all:
@--------------------------------------------
	stmfd sp!,{r0-r2, lr}
	ldr r0, =0x6000000
	ldr r1, =renderdata@ + 256 * 8
	bl dma_async
	ldmfd sp!, {r0-r2, pc}

@--------------------------------------------
render_sub:
@--------------------------------------------
	stmfd sp!,{r0-r4, lr}
	ldr r0, =0x6200000
	ldr r1, =renderdata
	
	ldr r4, =all_pix_start
	ldr r2, [r4]
	add r1, r2, lsl#8
	ldr r3, [r4, #4]
	sub r2, r3, r2

	ldr r3, =(0x80000000 | (1 << 26))
	add r3, r3, r2, lsl#6

	ldr r2, =0x040000D4
	str r1, [r2], #4
	str r0, [r2], #4
	str r3, [r2]
	ldmfd sp!, {r0-r4, pc}

@--------------------------------------------
render_sub2:
@--------------------------------------------
	stmfd sp!,{r0-r2, lr}
	ldr r0, =0x6200000
	ldr r1, =renderdata@ + 256 * 8
	bl dma_async
	ldmfd sp!, {r0-r2, pc}

@--------------------------------------------
dma_sync:
@r0 = dst, r1 = src, r2 = length(fixed to 256)
@--------------------------------------------
	stmfd sp!, {r2-r3}
	ldr r2, =0x040000D4
	ldr r3, =(0x80000000 | (1 << 26) | (256*240/4))
	str r1, [r2], #4
	str r0, [r2], #4
	str r3, [r2]
synclp2:
	ldr r3, [r2]
	tst r3, #0x80000000
	bne synclp2
	
	ldmfd sp!, {r2-r3}
	mov pc, lr

@--------------------------------------------
dma_async:
@r0 = dst, r1 = src, r2 = length(fixed to 256)
@when the code is located in the ictm section, we call this
@src = 0x040000B0 + (n*12)
@dest = 0x040000B4 + (n*12)
@cr = 0x040000B8 + (n*12)
@enable 0x80000000
@bit_32 1 << 26
@bit_16 0
@DMA_START_NOW 0
@DMA_SRC_FIX 1 << 24
@size = 64
@--------------------------------------------
	stmfd sp!, {r2-r3}
	ldr r2, =0x040000D4
	ldr r3, =(0x80000000 | (1 << 26) | (256*240/4))
	str r1, [r2], #4
	str r0, [r2], #4
	str r3, [r2]
	ldmfd sp!, {r2-r3}
	mov pc, lr

@--------------------------------------------
dma_async_fix:	
@--------------------------------------------
	stmfd sp!, {r2-r3}
	ldr r2, =0x040000D4
	ldr r3, =(0x80000000 | (1 << 26) | (256*240/4) | (1 << 24))
	str r1, [r2], #4
	str r0, [r2], #4
	str r3, [r2]
	ldmfd sp!, {r2-r3}
	mov pc, lr

@--------------------------------------------
dma_sync_fix:	
@--------------------------------------------
	stmfd sp!, {r2-r3}
	ldr r2, =0x040000D4
	ldr r3, =(0x80000000 | (1 << 26) | (256*240/4) | (1 << 24))
	str r1, [r2], #4
	str r0, [r2], #4
	str r3, [r2]
synclp:
	ldr r3, [r2]
	tst r3, #0x80000000
	bne synclp
	
	ldmfd sp!, {r2-r3}
	mov pc, lr

.section .bss, "aw"
.align 4

renderdata:
	.word 0
	.skip 256 * 256 + 16
renderbgdata:
	.skip 4

rev_data:
	.skip 256

BGwrite_data:
	.skip 36
SPwrite_data:
	.skip 36


	

