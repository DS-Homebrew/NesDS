@---------------------------------------------------------------------------------
	#include "equates.h"
@---------------------------------------------------------------------------------
	.global mapper69init
	countdown = mapperData+0
	irqen = mapperData+4
	cmd = mapperData+5
	video = mapperData+6		@ number of cycles per scanline
@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
@ Sunsoft FME-7, 5A & 5B
@ Used in:
@ Barcode World
@ Batman ROTJ
@ Gimmick
@ Gremlins (J)
@ Hebereke
mapper69init:
@---------------------------------------------------------------------------------
	.word write0,write1,void,void			@There is a music channel also

	mov r1,#-1
	mov r1,r1,lsr#16
	str_ r1,countdown

	ldr_ r1,emuFlags
	tst r1,#PALTIMING
	movne r1,#107				@PAL
	moveq r1,#113				@NTSC
	strb_ r1,video

	adr r0,hook
	str_ r0,scanlineHook

	bx lr
@---------------------------------------------------------------------------------
write0:		@$8000
@---------------------------------------------------------------------------------
	strb_ r0,cmd
	bx lr
@---------------------------------------------------------------------------------
write1:		@$A000
@---------------------------------------------------------------------------------
	ldrb_ r1,cmd
	movs r1,r1,lsl#29
	ldrcc r2,=writeCHRTBL
	adrcs r2,commandlist
	ldr pc,[r2,r1,lsr#27]

irqen69:
	strb_ r0,irqen
	bx lr
irqA69:
	strb_ r0,countdown+2
	bx lr
irqB69:
	strb_ r0,countdown+3
	bx lr
@---------------------------------------------------------------------------------
mapJinx:
@---------------------------------------------------------------------------------
	tst r0,#0x40
	ldr r1,=mem_R60			@Swap in mem at $6000-$7FFF.
	str_ r1,m6502ReadTbl+12
	ldreq r1,=empty_W		@ROM.
	ldrne r1,=sram_W		@sram.
	str_ r1,m6502WriteTbl+12
	beq map67_
	ldr r1,=NES_RAM-0x5800		@sram at $6000.
	str_ r1,m6502MemTbl+12
	bx lr
@---------------------------------------------------------------------------------
hook:
@---------------------------------------------------------------------------------
	ldrb_ r2,irqen
	tst r2,#0x80			@ Timer enabled?
	bxeq lr

	ldr_ r0,countdown
	ldrb_ r1,video			@ Number of cycles per scanline.
	subs r0,r0,r1,lsl#16
	str_ r0,countdown
	bxhi lr

	mov r1,#0
	strb_ r1,irqen
	ands r0,r2,#1			@ IRQ enabled?
	bne rp2A03SetIRQPin
	bx lr
@---------------------------------------------------------------------------------
commandlist:	.word mapJinx,map89_,mapAB_,mapCD_,mirrorKonami_,irqen69,irqA69,irqB69
@---------------------------------------------------------------------------------
